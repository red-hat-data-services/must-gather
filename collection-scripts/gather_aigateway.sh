#!/bin/bash
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"
source "${SCRIPT_DIR}/llm-d/xks_util.sh"

# AI Gateway controller and payload-processing CRDs.
resources=(
  "aiguardrails.inference.opendatahub.io"
  "externalmodels.inference.opendatahub.io"
  "externalproviders.inference.opendatahub.io"
)

# MaaS is optional within the AI Gateway component.
cluster_scoped_resources=()
cluster_scoped_resources+=(
  "aigateways.components.platform.opendatahub.io"
)
if [[ "${K8S_DISTRO}" == "ocp" || "${ENABLE_MAAS:-false}" == "true" ]]; then
  cluster_scoped_resources+=(
    "configs.maas.opendatahub.io"
  )
  resources+=(
    "aitenants.maas.opendatahub.io"
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

# Grid CRDs are cluster-scoped and optional within the AI Gateway component.
if [[ "${K8S_DISTRO}" == "ocp" || "${ENABLE_GRID:-false}" == "true" ]]; then
  cluster_scoped_resources+=(
    "siteinvites.grid.praxis.fast"
    "inferenceproviders.grid.praxis.fast"
    "gridsites.grid.praxis.fast"
    "gridnetworks.grid.praxis.fast"
    "agenttoolproviders.grid.praxis.fast"
  )
fi

if [[ "${K8S_DISTRO}" == "ocp" ]]; then
  get_operator_resource "${cluster_scoped_resources[@]}"
else
  for resource in "${cluster_scoped_resources[@]}"; do
    resource_group="${resource#*.}"
    resource_dir="${DST_DIR}/cluster-scoped-resources/${resource_group}"
    resource_name="${resource%%.*}"
    resource_output=$(mktemp)
    if $KUBECTL get "$resource" -o yaml > "$resource_output" 2>/dev/null; then
      mkdir -p "${resource_dir}"
      mv "$resource_output" "${resource_dir}/${resource_name}.yaml"
    else
      rm -f "$resource_output"
    fi
  done
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
