#!/bin/bash
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"

# MaaS core CRDs (maas.opendatahub.io)
resources=(
  "aitenants.maas.opendatahub.io"
  "configs.maas.opendatahub.io"
  "externalmodels.maas.opendatahub.io"
  "maasauthpolicies.maas.opendatahub.io"
  "maasmodelrefs.maas.opendatahub.io"
  "maassubscriptions.maas.opendatahub.io"
  "maastenantconfigs.maas.opendatahub.io"
  "tenants.maas.opendatahub.io"
)
# Inference CRDs (inference.opendatahub.io) — from ai-gateway-payload-processing
resources+=(
  "externalmodels.inference.opendatahub.io"
  "externalproviders.inference.opendatahub.io"
)
# Batch gateway CRD
resources+=(
  "llmbatchgateways.batch.llm-d.ai"
)

nslist=$(get_all_namespace "${resources[@]}")

run_mustgather "$nslist" "${resources[@]}"
