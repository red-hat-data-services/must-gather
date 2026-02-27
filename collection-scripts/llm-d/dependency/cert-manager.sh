#!/bin/bash
# cert-manager dependency gathering script - collects certificate management resources
# shellcheck disable=SC1091
source "$(dirname "$0")/../../common.sh"
source "$(dirname "$0")/../xks_util.sh"

# cert-manager core resources
# https://cert-manager.io/
# All are collected but only certain are in use
resources=(
    "certmanagers.operator.openshift.io"
    "issuers.cert-manager.io"
    "clusterissuers.cert-manager.io"
    "certificates.cert-manager.io"
    "certificaterequests.cert-manager.io"
    "orders.acme.cert-manager.io"
    "challenges.acme.cert-manager.io"
    "istiocsrs.operator.openshift.io"
)

# Get all namespaces where these resources exist
nslist=$(get_all_namespace "${resources[@]}")

# Run collection across all identified namespaces
run_k8sgather "$nslist" "${resources[@]}"

# Collect cert-manager operator and runtime namespaces
kubectl_inspect "namespace/cert-manager-operator" || echo "ERROR: Namespace cert-manager-operator not found"
kubectl_inspect "namespace/cert-manager" || echo "ERROR: Namespace cert-manager not found"