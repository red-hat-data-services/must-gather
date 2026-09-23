#!/bin/bash
# KServe component gathering script - collects ModelExpress resources
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/llm-d/xks_util.sh"

echo "=========================================="
echo "DEBUG: gather_modelexpress.sh is being executed"
echo "DEBUG: K8S_DISTRO=${K8S_DISTRO}"
echo "DEBUG: KUBECTL=${KUBECTL}"
echo "=========================================="

resources=(
    "modelmetadatas.modelexpress.nvidia.com"
    "modelcacheentries.modelexpress.nvidia.com"
    "modelexpressservers.modelexpress.opendatahub.io"
)

nslist=$(get_all_namespace "${resources[@]}")
if [[ "${K8S_DISTRO}" == "ocp" ]]; then
    run_mustgather "$nslist" "${resources[@]}"
else
    run_k8sgather "$nslist" "${resources[@]}"
fi

echo "=========================================="
echo "DEBUG: ModelExpress collection completed"
echo "=========================================="
