#!/bin/bash
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"
# resource for v1
resources=("mpijobs" "paddlejobs" "pytorchjob" "tfjob" "xgboostjob" "jaxjobs")
# resource for v2
resources+=("jobsetoperators" "trainjobs.trainer.kubeflow.org" "trainingruntimes.trainer.kubeflow.org" "clustertrainingruntimes.trainer.kubeflow.org")

nslist=$(get_all_namespace "${resources[@]}")

run_mustgather "$nslist" "${resources[@]}"

