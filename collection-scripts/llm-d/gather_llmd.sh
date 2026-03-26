#!/bin/bash
# LLM-D component gathering script - collects Kserve + llm-d related resources
# No need call gather_serving but running standalone
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

# OPERATOR_NS and APPLICATIONS_NS are already defined in the main gather script
# For non-OpenShift platforms, collect operator and applications namespaces
if [[ "${K8S_DISTRO}" != "ocp" ]]; then
    kubectl_inspect "namespace/$OPERATOR_NS" || echo "Error inspecting namespace/${OPERATOR_NS}"
    kubectl_inspect "namespace/$APPLICATIONS_NS" || echo "Error inspecting namespace/${APPLICATIONS_NS}"
fi

# Run dependency collection scripts in parallel (cert-manager, sail, lws)
echo "Collecting llm-d dependencies(operators) in parallel..."
declare -A pid_to_script
for script in "${SCRIPT_DIR}/llm-d/dependency"/*.sh; do
    if [[ -f "$script" ]]; then
        echo "Starting $(basename "$script")..."
        bash "$script" &
        pid_to_script[$!]="$script"
    fi
done
# Wait for all dependency scripts to complete
for pid in "${!pid_to_script[@]}"; do
    wait "$pid" || echo "ERROR: Failed to run ${pid_to_script[$pid]}"
done

resources+=(
    "dscinitialization"
    "datasciencecluster"
    "gatewayconfigs.services.platform.opendatahub.io"
    "kserves.components.platform.opendatahub.io"
    "mutatingwebhookconfigurations.admissionregistration.k8s.io"
    "validatingwebhookconfigurations.admissionregistration.k8s.io"
    "gatewayclasses"
)

# Core KServe resources
resources+=(
    "llminferenceserviceconfigs.serving.kserve.io"
    "llminferenceservices.serving.kserve.io"
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

# Gateway API Inference Extension (inference.networking.x-k8s.io)
# https://gateway-api-inference-extension.sigs.k8s.io/
resources+=(
    "inferencepools.inference.networking.k8s.io"
    # "inferencemodelrewrites.inference.networking.x-k8s.io" enabled for LoRA
    "inferenceobjectives.inference.networking.x-k8s.io"
    "inferencemodels.inference.networking.x-k8s.io"  # to be deleted
)

# Get all namespaces where these resources exist, excluding namespaces which have been fully inspected
nslist=$(get_all_namespace "${resources[@]}" | grep -v "^${APPLICATIONS_NS}$" | grep -v "^${OPERATOR_NS}$" | tr '\n' ' ')

# Run collection across all identified namespaces (except already fully inspected namespaces)
run_k8sgather "$nslist" "${resources[@]}"

echo "=========================================="
echo "DEBUG: LLM-D resource collection completed"
echo "=========================================="
