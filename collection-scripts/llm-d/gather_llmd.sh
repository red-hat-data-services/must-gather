#!/bin/bash
# LLM-D resource gathering script, invoked by the KServe collector.
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")/..}"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/llm-d/xks_util.sh"

echo "=========================================="
echo "DEBUG: gather_llmd.sh is being executed"
echo "DEBUG: K8S_DISTRO=${K8S_DISTRO}"
echo "DEBUG: KUBECTL=${KUBECTL}"
echo "=========================================="


# Collect cluster-level information
echo "Collecting cluster information..."
bash "${SCRIPT_DIR}/llm-d/gather_cluster.sh" || echo "WARNING: Failed to collect cluster information"

# OPERATOR_NS, APPLICATIONS_NS and HELM_CHART_NS are already defined in the main gather script
# For non-OpenShift platforms, collect operator, applications and helm chart namespaces
if [[ "${K8S_DISTRO}" != "ocp" ]]; then
    kubectl_inspect "namespace/$OPERATOR_NS" || echo "Error inspecting namespace/${OPERATOR_NS}"
    kubectl_inspect "namespace/$APPLICATIONS_NS" || echo "Error inspecting namespace/${APPLICATIONS_NS}"
    kubectl_inspect "namespace/$HELM_CHART_NS" || echo "Error inspecting namespace/${HELM_CHART_NS}"
    kubectl_inspect "namespace/$CLOUDMANAGER_NS" || echo "Error inspecting namespace/${CLOUDMANAGER_NS}"
fi

# Collect LLM-D dependencies, including LWS resources.
for dependency in cert-manager sail lws; do
    script="${SCRIPT_DIR}/llm-d/dependency/${dependency}.sh"
    bash "$script" || echo "ERROR: Failed to run ${script}"
done

# KServe already collected full namespaces containing LLMInferenceServices.
llmisvc_namespaces=$(get_all_namespace "llminferenceservices.serving.kserve.io" | \
    grep -v "^${OPERATOR_NS}$" | grep -v "^${APPLICATIONS_NS}$" | grep -v "^${HELM_CHART_NS}$" | grep -v "^${CLOUDMANAGER_NS}$" | tr '\n' ' ')

resources+=(
    "gatewayconfigs.services.platform.opendatahub.io"
    "mutatingwebhookconfigurations.admissionregistration.k8s.io"
    "validatingwebhookconfigurations.admissionregistration.k8s.io"
)

# LLM-D monitoring resources
resources+=(
    "servicemonitors.monitoring.coreos.com"
    "podmonitors.monitoring.coreos.com"
)

# Gateway API resources (standard Kubernetes)
resources+=(
    "gatewayclasses.gateway.networking.k8s.io"
    "gateways.gateway.networking.k8s.io"
    "httproutes.gateway.networking.k8s.io"
    "grpcroutes.gateway.networking.k8s.io"
    "referencegrants.gateway.networking.k8s.io"
)

# InferencePool is provided by GIE; Router request APIs are in llm-d.ai.
resources+=(
    "inferencemodelrewrites.llm-d.ai"
    "inferenceobjectives.llm-d.ai"
)

# Get all namespaces where these resources exist, excluding namespaces which have been fully inspected
nslist=$(get_all_namespace "${resources[@]}" | grep -v "^${APPLICATIONS_NS}$" | grep -v "^${OPERATOR_NS}$" | grep -v "^${HELM_CHART_NS}$" | grep -v "^${CLOUDMANAGER_NS}$")
# Exclude llmisvc namespaces already fully inspected above
for ns in $llmisvc_namespaces; do
    nslist=$(echo "$nslist" | grep -v "^${ns}$")
done
nslist=$(echo "$nslist" | tr '\n' ' ')

# Run collection across all identified namespaces (except already fully inspected namespaces)
run_k8sgather "$nslist" "${resources[@]}"

# General monitoring collection; this is independent of optional autoscaler support.
bash "${SCRIPT_DIR}/llm-d/gather_o11y.sh" || echo "WARNING: Failed to collect observability resources"

echo "=========================================="
echo "DEBUG: LLM-D resource collection completed"
echo "=========================================="
