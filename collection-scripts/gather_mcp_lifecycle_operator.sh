#!/bin/bash
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"
resources=("mcpservers.mcp.x-k8s.io")

nslist=$(get_all_namespace "${resources[@]}")

run_mustgather "$nslist" "${resources[@]}"
