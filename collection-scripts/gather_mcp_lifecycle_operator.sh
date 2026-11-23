#!/bin/bash
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"
resources=("mcpservers.mcp.x-k8s.io" "mcpgatewaybindings.mcp.x-k8s.io" "mcplifecycleoperators.components.platform.opendatahub.io" "mcpserverregistrations.mcp.kuadrant.io" "mcpgatewayextensions.mcp.kuadrant.io" "gateways.gateway.networking.k8s.io")

nslist=$(get_all_namespace "${resources[@]}")

run_mustgather "$nslist" "${resources[@]}"
