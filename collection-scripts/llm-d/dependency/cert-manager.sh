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
    "infrastructures.config.openshift.io"
)

# Get all namespaces where these resources exist
nslist=$(get_all_namespace "${resources[@]}")

# Run collection across all identified namespaces
run_k8sgather "$nslist" "${resources[@]}"

# Collect cert-manager operator and runtime namespaces
# User can override or fallback to default namespaces
CERT_MANAGER_OPERATOR_NS=${CERT_MANAGER_OPERATOR_NAMESPACE:-cert-manager-operator}
kubectl_inspect "namespace/$CERT_MANAGER_OPERATOR_NS" || echo "WARNING: Namespace ${CERT_MANAGER_OPERATOR_NS} not found"
CERT_MANAGER_NS=${CERT_MANAGER_NAMESPACE:-cert-manager}
kubectl_inspect "namespace/$CERT_MANAGER_NS" || echo "WARNING: Namespace ${CERT_MANAGER_NS} not found"