#!/bin/bash
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/llm-d/xks_util.sh"

if [[ "${K8S_DISTRO}" != "ocp" && "${COMPONENT:-}" == "aigateway" ]]; then
  component_resource="aigateways.components.platform.opendatahub.io"
  if $KUBECTL get "$component_resource" --no-headers 2>/dev/null | grep -q .; then
    component_resource_dir="${DST_DIR}/cluster-scoped-resources/components.platform.opendatahub.io"
    mkdir -p "$component_resource_dir"
    $KUBECTL get "$component_resource" -o yaml > "${component_resource_dir}/aigateways.yaml" 2>/dev/null
  fi
fi

# AI Gateway controller and payload-processing CRDs.
resources=(
  "aiguardrails.inference.opendatahub.io"
  "externalmodels.inference.opendatahub.io"
  "externalproviders.inference.opendatahub.io"
)

# MaaS is optional within the AI Gateway component.
if [[ "${K8S_DISTRO}" == "ocp" || "${ENABLE_MAAS:-false}" == "true" ]]; then
  resources+=(
    "aitenants.maas.opendatahub.io"
    "configs.maas.opendatahub.io"
    "externalmodels.maas.opendatahub.io"
    "maasauthpolicies.maas.opendatahub.io"
    "maasmodelrefs.maas.opendatahub.io"
    "maassubscriptions.maas.opendatahub.io"
    "maastenantconfigs.maas.opendatahub.io"
    "tenants.maas.opendatahub.io"
    "ratelimitpolicies.kuadrant.io"
    "kuadrants.kuadrant.io"
    "tokenratelimitpolicies.kuadrant.io"
  )
fi

nslist=$(get_all_namespace "${resources[@]}")

if [[ "${K8S_DISTRO}" == "ocp" ]]; then
  run_mustgather "$nslist" "${resources[@]}"
else
  run_k8sgather "$nslist" "${resources[@]}"
fi

# OCP collects Batch Gateway by default; xKS enables it with ENABLE_BATCH_GATEWAY.
if [[ "${K8S_DISTRO}" == "ocp" || "${ENABLE_BATCH_GATEWAY:-false}" == "true" ]]; then
  batch_gateway_resource="llmbatchgateways.batch.llm-d.ai"
  batch_gateway_nslist=$(get_all_namespace "$batch_gateway_resource")
  run_k8sgather "$batch_gateway_nslist" "$batch_gateway_resource"
  "${SCRIPT_DIR}/llm-d/gather_batch_gateway.sh"
fi
