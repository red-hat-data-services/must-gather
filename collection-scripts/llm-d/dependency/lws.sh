#!/bin/bash
# Leader Worker Set dependency gathering script - collects LWS resources
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")/../..}"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/llm-d/xks_util.sh"

# LWS APIs are used on both OpenShift and xKS.
resources=(
    "leaderworkersets.leaderworkerset.x-k8s.io"
    "disaggregatedsets.disaggregatedset.x-k8s.io"
    "disaggregatedsetrolescalers.disaggregatedset.x-k8s.io"
)
nslist=$(get_all_namespace "${resources[@]}")
run_k8sgather "$nslist" "${resources[@]}"

# The LWS Operator API exists only on OpenShift.
if [[ "${K8S_DISTRO}" == "ocp" ]]; then
    get_operator_resource "leaderworkersetoperators.operator.openshift.io"
fi

# Collect the LWS controller namespace. The namespace differs by distro.
if [[ "${K8S_DISTRO}" == "ocp" ]]; then
    DEFAULT_LWS_NS="openshift-lws-operator"
else
    DEFAULT_LWS_NS="lws-system"
fi
LWS_NS=${LWS_NAMESPACE:-${DEFAULT_LWS_NS}}
kubectl_inspect "namespace/$LWS_NS" || echo "WARNING: Namespace ${LWS_NS} not found"
