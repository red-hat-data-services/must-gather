#!/bin/bash
# KServe component collection, including llm-d resources.
# shellcheck disable=SC1091
: "${SCRIPT_DIR:=$(dirname "$0")}"

if [[ "${K8S_DISTRO}" == "ocp" ]]; then
    "${SCRIPT_DIR}/gather_serving_ocp.sh"
else
    "${SCRIPT_DIR}/gather_serving.sh"
fi
"${SCRIPT_DIR}/llm-d/gather_llmd.sh"

if [[ "${K8S_DISTRO}" == "ocp" || "${ENABLE_MODELEXPRESS:-false}" == "true" ]]; then
    "${SCRIPT_DIR}/gather_modelexpress.sh"
fi
