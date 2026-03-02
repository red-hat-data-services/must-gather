#!/bin/bash
# collects Prometheus Operator monitoring resources
# shellcheck disable=SC1091
source "$(dirname "$0")/../common.sh"

echo "=========================================="
echo "DEBUG: gather_o11y.sh is being executed"
echo "DEBUG: K8S_DISTRO=${K8S_DISTRO}"
echo "DEBUG: KUBECTL=${KUBECTL}"
echo "=========================================="

# AKS monitoring type: "managed" for Azure Managed Prometheus (AMP), "self-hosted" for kube-prometheus-stack
# Default to self-hosted when not specified
AKS_MONITORING_TYPE=${AKS_MONITORING_TYPE:-self-hosted}

# Collect monitoring based on deployment type
if [[ "${K8S_DISTRO}" == "aks" && "${AKS_MONITORING_TYPE}" == "managed" ]]; then
    # Azure Managed Prometheus (AMP) - collect ama-metrics pods and logs from kube-system
    AMA_NS="kube-system"
    AMA_DIR="${DST_DIR}/namespaces/${AMA_NS}/aks-managed-prometheus"
    mkdir -p "${AMA_DIR}/pods"

    echo "INFO: Collecting Azure Managed Prometheus (ama-metrics) pods and logs from ${AMA_NS}"

    # Collect all ama-metrics pods with logs (from DaemonSet and ReplicaSets)
    for pod in $($KUBECTL get pods -n "${AMA_NS}" -o name 2>/dev/null | grep '^pod/ama-metrics' | sed 's|^pod/||'); do
        pod_dir="${AMA_DIR}/pods/${pod}"
        mkdir -p "${pod_dir}"

        # Get pod yaml
        $KUBECTL get pod "$pod" -n "${AMA_NS}" -o yaml > "${pod_dir}/${pod}.yaml" 2>/dev/null

        # Get logs for each container
        for container in $($KUBECTL get pod "$pod" -n "${AMA_NS}" -o jsonpath='{.spec.containers[*].name}' 2>/dev/null); do
            mkdir -p "${pod_dir}/${container}/logs"
            # shellcheck disable=SC2086,SC2154
            $KUBECTL logs "$pod" -n "${AMA_NS}" -c "$container" $log_collection_args > "${pod_dir}/${container}/logs/current.log" 2>/dev/null
            # shellcheck disable=SC2086,SC2154
            $KUBECTL logs "$pod" -n "${AMA_NS}" -c "$container" --previous $log_collection_args > "${pod_dir}/${container}/logs/previous.log" 2>/dev/null
        done
    done
else
    # Self-hosted monitoring (kube-prometheus-stack)

    # Prometheus Operator resources (monitoring.coreos.com)
    # https://github.com/prometheus-operator/prometheus-operator
    resources=(
        "servicemonitors.monitoring.coreos.com" # dupe: already in gather_llmd.sh
        "podmonitors.monitoring.coreos.com"     # dupe: already in gather_llmd.sh
        "prometheusrules.monitoring.coreos.com"
        "prometheuses.monitoring.coreos.com"
        "alertmanagers.monitoring.coreos.com"
        "alertmanagerconfigs.monitoring.coreos.com"
        "probes.monitoring.coreos.com"
        "thanosrulers.monitoring.coreos.com"
    )

    # Get all namespaces where these resources exist
    nslist=$(get_all_namespace "${resources[@]}")

    # Run collection across all identified namespaces (for ServiceMonitor/PodMonitor CRDs)
    run_k8sgather "$nslist" "${resources[@]}"

    # Collect monitoring namespace (Prometheus/Grafana/Alertmanager pods and logs)
    # Use user override, then distro default, then fallback to monitoring
    MONITORING_NS=${MONITORING_NAMESPACE:-${DEFAULT_MONITORING_NS:-monitoring}}
    kubectl_inspect "namespace/$MONITORING_NS" || echo "ERROR: Namespace ${MONITORING_NS} not found"
fi
