#!/bin/bash
# Leader Worker Set dependency gathering script - collects LWS resources
# shellcheck disable=SC1091
source "$(dirname "$0")/../../common.sh"
source "$(dirname "$0")/../xks_util.sh"

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
kubectl_inspect "namespace/openshift-lws-operator" || echo "WARNING: Namespace openshift-lws-operator not found"