#!/bin/bash
# LLM-D component gathering script - collects workload-variant-autoscaler related resources
# shellcheck disable=SC1091
source "$(dirname "$0")/../common.sh"

echo "=========================================="
echo "DEBUG: gather_wva.sh is being executed"
echo "DEBUG: K8S_DISTRO=${K8S_DISTRO}"
echo "DEBUG: KUBECTL=${KUBECTL}"
echo "=========================================="

# WVA depends on observability
echo "Collecting observability resources..."
bash "$(dirname "$0")/gather_o11y.sh" || echo "WARNING: Failed to collect observability resources"

# KEDA (Kubernetes Event Driven Autoscaling)
resources+=(
    "scaledobjects.keda.sh"
    "scaledjobs.keda.sh"
    "triggerauthentications.keda.sh"
    "clustertriggerauthentications.keda.sh"
    "variantautoscalings.llmd.ai"
)

# llm-d
resources+=(
    "variantautoscalings.llmd.ai"
)

# Get all namespaces where these resources exist
nslist=$(get_all_namespace "${resources[@]}")

# Run collection across all identified namespaces
run_k8sgather "$nslist" "${resources[@]}"
