#!/bin/bash
# KServe resource collection for xKS clusters.
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/llm-d/xks_util.sh"
# shellcheck source=gather_serving_resources.sh
source "${SCRIPT_DIR}/gather_serving_resources.sh"

# resources is assigned by the sourced shared-resource file.
# shellcheck disable=SC2154
nslist=$(get_all_namespace "${resources[@]}")
for ns in $nslist; do
    kubectl_inspect "namespace/$ns" || echo "Error inspecting namespace/${ns}"
done
