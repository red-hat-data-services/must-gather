#!/bin/bash
# KServe resource collection for OpenShift.
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/gather_serving_resources.sh"

nslist=$(get_all_namespace "${resources[@]}")
run_mustgather "$nslist" "${resources[@]}"
