#!/bin/bash
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"
resources=("admissionchecks" "cohorts" "clusterqueues" "localqueues" "multikueueclusters" "multikueueconfigs" "provisioningrequestconfigs" "resourceflavors" "workloads" "workloadpriorityclasses")

nslist=$(get_all_namespace "${resources[@]}")

run_mustgather "$nslist" "${resources[@]}"
