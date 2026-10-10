#!/bin/bash
# shellcheck disable=SC1091,SC2086,SC2154
: "${SCRIPT_DIR:=$(dirname "$0")}"
source "${SCRIPT_DIR}/common.sh"

DATA_REGISTRIES_NS=${DATA_REGISTRIES_NAMESPACE:-rhoai-data-registries}

echo "Collecting Data Registry namespace: ${DATA_REGISTRIES_NS}..."
oc adm inspect $log_collection_args "namespace/${DATA_REGISTRIES_NS}" --dest-dir "$DST_DIR" \
    || echo "Error inspecting namespace/${DATA_REGISTRIES_NS}"

enabled_featurestores=$(
    oc get featurestores --all-namespaces -o json 2>/dev/null |
        jq -r '.items[] | select(.metadata.annotations["dataregistry.opendatahub.io/enabled"] == "true") | [.metadata.namespace, .metadata.name] | @tsv'
)

while IFS=$'\t' read -r featurestore_namespace featurestore; do
    if [ -z "${featurestore_namespace}" ] || [ -z "${featurestore}" ]; then
        continue
    fi
    oc adm inspect $log_collection_args "featurestore/${featurestore}" \
        -n "${featurestore_namespace}" --dest-dir "$DST_DIR" \
        || echo "Error inspecting FeatureStore ${featurestore} in ${featurestore_namespace}"
done <<< "${enabled_featurestores}"
