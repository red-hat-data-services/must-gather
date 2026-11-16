#!/bin/bash
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"
: "${KUBECTL:=kubectl}"
set -o pipefail
if ! command -v jq >/dev/null 2>&1; then
    echo "ERROR: OpenShell collection requires jq for redaction" >&2
    exit 1
fi
redactor="${SCRIPT_DIR}/openshell/redact.jq"

# Never write raw API responses or logs to disk, including command errors.
collect_json() {
    local destination="$1"
    shift
    "${KUBECTL}" get "$@" -o json 2>/dev/null | \
        jq --argjson logs false -f "$redactor" > "$destination" || {
        rm -f "$destination"
        echo "WARNING: could not collect sanitized $*" >&2
    }
}

# OpenShell's Kubernetes backend can use the optional Agent Sandbox API.
resources=()
if "${KUBECTL}" api-resources --api-group=agents.x-k8s.io -o name | \
    grep -qx 'sandboxes.agents.x-k8s.io'; then
    resources+=("sandboxes.agents.x-k8s.io")
fi

# Gateways and shared supervisors use Helm labels. Sandbox pods and managed
# workspace namespaces use OpenShell labels, including workspaces outside the
# gateway namespace. Keep discovery independent of release and namespace names.
nslist=$(
    {
        printf '%s\n' "${OPENSHELL_NAMESPACE:-}"
        "${KUBECTL}" get deployments,statefulsets,pods --all-namespaces \
            -l 'app.kubernetes.io/name in (openshell,openshell-supervisor)' \
            -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}'
        "${KUBECTL}" get pods --all-namespaces \
            -l openshell.ai/managed-by=openshell \
            -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}'
        "${KUBECTL}" get pods --all-namespaces \
            -l openshell.ai/boundary-role=workload \
            -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}'
        "${KUBECTL}" get deployments --all-namespaces \
            -l 'app in (agent-sandbox-controller,sandbox-router)' \
            -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}'
        for resource in "${resources[@]}"; do
            "${KUBECTL}" get "$resource" --all-namespaces \
                -l openshell.ai/managed-by=openshell \
                -o jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}'
        done
        "${KUBECTL}" get namespaces \
            -l openshell.ai/managed-by=openshell \
            -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'
    } | sort -u | sed '/^$/d'
)

# Use explicit resource types: namespace inspection also collects Secrets and
# logs from supervisors and user workloads, even when they share the gateway NS.
if [[ -z "$nslist" ]]; then
    exit 0
fi
runtime_dir="${DST_DIR}/openshell/runtime"
mkdir -p "$runtime_dir"
collect_json "$runtime_dir/runtimeclasses.json" runtimeclasses.node.k8s.io
if "${KUBECTL}" api-resources --api-group=kataconfiguration.openshift.io -o name | \
    grep -qx 'kataconfigs.kataconfiguration.openshift.io'; then
    collect_json "$runtime_dir/kataconfigs.json" kataconfigs.kataconfiguration.openshift.io
fi

for ns in $nslist; do
    ns_dir="${DST_DIR}/namespaces/${ns}/openshell"
    mkdir -p "$ns_dir"
    for resource in pods deployments.apps statefulsets.apps daemonsets.apps \
        replicasets.apps jobs.batch services persistentvolumeclaims \
        networkpolicies.networking.k8s.io events configmaps "${resources[@]}"; do
        collect_json "$ns_dir/${resource}.json" "$resource" -n "$ns"
    done

    # Select gateway pods only. Explicitly exclude workload/supervisor markers
    # even if a workload also carries the gateway's application label.
    gateway_selector='app.kubernetes.io/name=openshell,!openshell.ai/boundary-role,!openshell.ai/sandbox-id,openshell.ai/managed-by!=openshell'
    while IFS=$'\t' read -r pod container; do
        [[ -z "$pod" || -z "$container" ]] && continue
        log_dir="$ns_dir/pods/$pod/$container/logs"
        mkdir -p "$log_dir"
        # shellcheck disable=SC2086
        "${KUBECTL}" logs "$pod" -n "$ns" -c "$container" $log_collection_args 2>/dev/null | \
            jq -Rr --argjson logs true -f "$redactor" > "$log_dir/current.log"
        # shellcheck disable=SC2086
        "${KUBECTL}" logs "$pod" -n "$ns" -c "$container" --previous $log_collection_args 2>/dev/null | \
            jq -Rr --argjson logs true -f "$redactor" > "$log_dir/previous.log"
    done < <("${KUBECTL}" get pods -n "$ns" -l "$gateway_selector" -o json 2>/dev/null | \
        jq -r '.items[] | select(.metadata.labels["app.kubernetes.io/name"] == "openshell")
          | select(.metadata.labels["openshell.ai/boundary-role"] == null)
          | select(.metadata.labels["openshell.ai/sandbox-id"] == null)
          | select(.metadata.labels["openshell.ai/managed-by"] != "openshell")
          | .metadata.name as $pod | .spec.containers[]
          | select(.name == "openshell-gateway") | [$pod, .name] | @tsv')
done
# Missing previous logs and optional APIs must not fail the collector.
exit 0
