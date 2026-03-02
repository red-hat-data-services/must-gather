#!/bin/bash
# LLM-D component gathering script - collects Kserve + llm-d related resources
# No need call gather_serving but running standalone
# shellcheck disable=SC1091
source "$(dirname "$0")/../common.sh"
source "$(dirname "$0")/xks_util.sh"

echo "=========================================="
echo "DEBUG: gather_llmd.sh is being executed"
echo "DEBUG: K8S_DISTRO=${K8S_DISTRO}"
echo "DEBUG: KUBECTL=${KUBECTL}"
echo "=========================================="


# Collect cluster-level information
echo "Collecting cluster information..."
bash "$(dirname "$0")/gather_cluster.sh" || echo "WARNING: Failed to collect cluster information"

APPLICATIONS_NS="opendatahub" # hardcode to opendatahub for now where kserve controller is deployed
# Mainly get kserve controller pods
kubectl_inspect "namespace/$APPLICATIONS_NS" || echo "Error inspecting namespace/${APPLICATIONS_NS}"

# Run dependency collection scripts (cert-manager, sail, lws)
echo "Collecting llm-d dependencies(operators)..."
for script in "$(dirname "$0")/dependency"/*.sh; do
    if [[ -f "$script" ]]; then
        echo "Running $(basename "$script")..."
        bash "$script" || echo "ERROR: Failed to run $script"
    fi
done

# Core KServe resources
resources+=(
    "llminferenceserviceconfigs.serving.kserve.io"
    "llminferenceservices.serving.kserve.io"
    "servicemonitors.monitoring.coreos.com"
    "podmonitors.monitoring.coreos.com"
)

# Gateway API Inference Extension (inference.networking.x-k8s.io)
# https://gateway-api-inference-extension.sigs.k8s.io/
resources+=(
    "inferencepools.inference.networking.k8s.io"
    # "inferencemodelrewrites.inference.networking.x-k8s.io" enabled for LoRA
    "inferenceobjectives.inference.networking.x-k8s.io"
    "inferencemodels.inference.networking.x-k8s.io"  # to be deleted
)

# Get all namespaces where these resources exist
nslist=$(get_all_namespace "${resources[@]}")

# Run collection across all identified namespaces
run_k8sgather "$nslist" "${resources[@]}"
