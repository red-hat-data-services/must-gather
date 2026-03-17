#!/bin/bash
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"
resources=("odhdashboardconfigs" "acceleratorprofiles" "hardwareprofiles.dashboard.opendatahub.io" "odhapplications" "odhdocuments" "odhquickstarts")

nslist=$(get_all_namespace "${resources[@]}")

run_mustgather "$nslist" "${resources[@]}"

