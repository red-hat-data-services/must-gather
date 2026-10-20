#!/bin/bash
# KServe resource collection for xKS clusters.
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/llm-d/xks_util.sh"
# shellcheck source=gather_serving_resources.sh
source "${SCRIPT_DIR}/gather_serving_resources.sh"

# shellcheck disable=SC2154
for resource in "${cluster_scoped_resources[@]}"; do
  resource_group="${resource#*.}"
  resource_dir="${DST_DIR}/cluster-scoped-resources/${resource_group}"
  resource_name="${resource%%.*}"
  resource_output=$(mktemp)
  if kubectl get "$resource" -o yaml > "$resource_output" 2>/dev/null; then
    mkdir -p "${resource_dir}"
    mv "$resource_output" "${resource_dir}/${resource_name}.yaml"
  else
    rm -f "$resource_output"
  fi
done

# resources is assigned by the sourced shared-resource file.
# shellcheck disable=SC2154
nslist=$(get_all_namespace "${resources[@]}")
for ns in $nslist; do
    kubectl_inspect "namespace/$ns" || echo "Error inspecting namespace/${ns}"
done
