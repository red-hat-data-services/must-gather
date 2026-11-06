#!/bin/bash
# shellcheck disable=SC1091,SC2086,SC2154
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"

DATA_REGISTRY_NS=${DATA_REGISTRY_NS:-rhoai-data-registry}

echo "Collecting Data Registry namespace: ${DATA_REGISTRY_NS}..."
oc adm inspect $log_collection_args "namespace/${DATA_REGISTRY_NS}" --dest-dir "$DST_DIR" \
    || echo "Error inspecting namespace/${DATA_REGISTRY_NS}"
