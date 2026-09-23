#!/bin/bash
# Default component collection for xKS platforms.
: "${SCRIPT_DIR:=$(dirname "$0")}"

"${SCRIPT_DIR}/gather_kserve.sh"
"${SCRIPT_DIR}/gather_aigateway.sh"
