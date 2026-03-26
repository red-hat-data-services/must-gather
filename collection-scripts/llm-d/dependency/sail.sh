#!/bin/bash
# Sail Operator dependency gathering script - collects Istio lifecycle management resources
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")/../..}"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/llm-d/xks_util.sh"

# Sail Operator resources
# All are collected but only certain are in use
# https://github.com/istio-ecosystem/sail-operator
resources=(
    "istios.sailoperator.io"
    "istiorevisions.sailoperator.io"
    "istiorevisiontags.sailoperator.io"
    "istiocnis.sailoperator.io"
    "ztunnels.sailoperator.io"
)

# Istio networking resources
resources+=(
    "virtualservices.networking.istio.io"
    "destinationrules.networking.istio.io"
    "envoyfilters.networking.istio.io"
    "gateways.networking.istio.io"
    "proxyconfigs.networking.istio.io"
    "serviceentries.networking.istio.io"
    "sidecars.networking.istio.io"
    "workloadentries.networking.istio.io"
    "workloadgroups.networking.istio.io"
)

# Istio security resources
resources+=(
    "authorizationpolicies.security.istio.io"
    "peerauthentications.security.istio.io"
    "requestauthentications.security.istio.io"
)

# Istio telemetry resources
resources+=(
    "telemetries.telemetry.istio.io"
)

# Istio extensions
resources+=(
    "wasmplugins.extensions.istio.io"
)

# Get all namespaces where these resources exist
nslist=$(get_all_namespace "${resources[@]}")

# Run collection across all identified namespaces
run_k8sgather "$nslist" "${resources[@]}"

# Collect Istio namespace (Sail Operator and Istio control plane)
# Use user override, then distro default, then fallback to istio-system
ISTIO_NS=${ISTIO_NAMESPACE:-${DEFAULT_ISTIO_NS:-istio-system}}
kubectl_inspect "namespace/$ISTIO_NS" || echo "ERROR: Namespace ${ISTIO_NS} not found"