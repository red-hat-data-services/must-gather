#!/bin/bash
# shellcheck disable=SC1091
# Note: Core cluster resources (PVs, storage classes, etc.) are collected by gather script
# This script collects cluster info, API resources, and detailed node information

source "$(dirname "$0")/../common.sh"
source "$(dirname "$0")/xks_util.sh"

dest_dir="${DST_DIR}/cluster-scoped-resources"
mkdir -p "${dest_dir}"

echo "Collecting cluster information..."

# Cluster info (not collected by gather)
# Strip ANSI color codes using sed
$KUBECTL cluster-info 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' > "${dest_dir}/cluster-info.txt"

# API resources list namespace-scoped and cluster-scoped(not collected by gather)
$KUBECTL api-resources > "${dest_dir}/api-resources.txt" 2>/dev/null

# Collect detailed node information
node_dir="${dest_dir}/nodes"
mkdir -p "${node_dir}"

echo "Collecting detailed node information..."

for node in $($KUBECTL get nodes -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
    $KUBECTL get node "$node" -o yaml > "${node_dir}/${node}.yaml" 2>/dev/null
done

# Auto-discover and collect all cluster-scoped resources
collect_cluster_scoped_resources

echo "Additional cluster information collected"
