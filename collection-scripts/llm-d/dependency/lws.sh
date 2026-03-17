#!/bin/bash
# Leader Worker Set dependency gathering script - collects LWS resources
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")/../..}"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/llm-d/xks_util.sh"

# Leader Worker Set resources
# https://github.com/kubernetes-sigs/lws
resources=(
    "leaderworkersets.leaderworkerset.x-k8s.io"
    "leaderworkersetoperators.operator.openshift.io"
)

# Get all namespaces where these resources exist
nslist=$(get_all_namespace "${resources[@]}")

# Run collection across all identified namespaces
run_k8sgather "$nslist" "${resources[@]}"

# Collect LWS operator namespace
# User can override or fallback to openshift-lws-operator
LWS_NS=${LWS_NAMESPACE:-openshift-lws-operator}
kubectl_inspect "namespace/$LWS_NS" || echo "WARNING: Namespace ${LWS_NS} not found"