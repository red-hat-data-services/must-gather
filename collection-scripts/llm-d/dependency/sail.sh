#!/bin/bash
# Sail Operator dependency gathering script - collects Istio lifecycle management resources
# shellcheck disable=SC1091
source "$(dirname "$0")/../../common.sh"
source "$(dirname "$0")/../xks_util.sh"

# Sail Operator resources (Istio lifecycle management)
# https://github.com/istio-ecosystem/sail-operator
# All are collected but only certain are in use
resources=(
    "istios.sailoperator.io"
    "istiorevisions.sailoperator.io"
    "istiorevisiontags.sailoperator.io"
    "istiocnis.sailoperator.io"
    "ztunnels.sailoperator.io"
)

# Get all namespaces where these resources exist
nslist=$(get_all_namespace "${resources[@]}")

# Run collection across all identified namespaces
run_k8sgather "$nslist" "${resources[@]}"

# Collect Istio namespace (Sail Operator and Istio control plane)
# Use user override, then distro default, then fallback to istio-system
ISTIO_NS=${ISTIO_NAMESPACE:-${DEFAULT_ISTIO_NS:-istio-system}}
kubectl_inspect "namespace/$ISTIO_NS" || echo "ERROR: Namespace ${ISTIO_NS} not found"