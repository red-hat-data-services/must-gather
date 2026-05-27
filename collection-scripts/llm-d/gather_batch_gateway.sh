#!/bin/bash
# LLM-D component gathering script - collects batch-gateway related resources
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")/..}"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/llm-d/xks_util.sh"

echo "=========================================="
echo "DEBUG: gather_batch_gateway.sh is being executed"
echo "DEBUG: K8S_DISTRO=${K8S_DISTRO}"
echo "DEBUG: KUBECTL=${KUBECTL}"
echo "=========================================="

BATCH_GATEWAY_NS=${BATCH_GATEWAY_NAMESPACE:-batch-gateway}

# Full namespace inspection for batch gateway (pods, logs, events, deployments, services, etc.)
echo "Collecting batch gateway namespace: ${BATCH_GATEWAY_NS}..."
kubectl_inspect "namespace/${BATCH_GATEWAY_NS}" || echo "WARNING: Failed to collect batch gateway namespace ${BATCH_GATEWAY_NS}"

# Collect Helm release information for batch-gateway
echo "Collecting batch gateway Helm release information..."
collect_helm_releases "${BATCH_GATEWAY_NS}" "batch-gateway"

echo "=========================================="
echo "DEBUG: Batch gateway collection completed"
echo "=========================================="
