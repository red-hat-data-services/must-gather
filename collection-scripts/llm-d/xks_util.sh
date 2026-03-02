#!/bin/bash
# Common auto-discovery function for both namespaced and cluster-scoped resources
function auto_discover_resources() {
    local namespaced="$1"
    local dest_dir="$2"
    local namespace="$3"   # only used if namespaced=true

    local scope_flag="--namespaced=${namespaced}"
    local ns_flag=""
    if [[ "$namespaced" == "true" ]]; then
        ns_flag="-n ${namespace}"
    fi

    # shellcheck disable=SC2086
    while IFS= read -r line; do
        local resource_name
        local api_version
        resource_name=$(echo "$line" | awk '{print $1}')
        api_version=$(echo "$line" | awk '{print $3}')
        [[ -z "$resource_name" ]] && continue # handle warning line

        # Check if any resources of this type exist
        if ! $KUBECTL get "$resource_name" $ns_flag --no-headers 2>/dev/null | grep -q .; then
            continue  # skip if not exist
        fi

        local api_group="${api_version%/*}"
        [[ "$api_version" != */* ]] && api_group="core" # core only show as v1
        local subdir="${api_group}"

        mkdir -p "${dest_dir}/${subdir}"

        # Special handling for events: transform 'kind: List' to 'kind: EventList'
        # This is needed for oc adm must-gather post-processing
        if [[ "$resource_name" == "events" ]]; then
            $KUBECTL get "$resource_name" $ns_flag -o yaml 2>/dev/null | \
                sed 's/^kind: List$/kind: EventList/' > "${dest_dir}/${subdir}/${resource_name}.yaml"
        else
            $KUBECTL get "$resource_name" $ns_flag -o yaml > "${dest_dir}/${subdir}/${resource_name}.yaml" 2>/dev/null
        fi
    done < <($KUBECTL api-resources $scope_flag --no-headers 2>/dev/null)
}

# kubectl-based replacement for 'oc adm inspect'
# Collects: namespace yaml, all resources, pod logs, events etc
function kubectl_inspect() {
    local resource="$1"
    local namespace="$2"
    local dest_dir="${DST_DIR}"

    # Handle namespace/name format
    if [[ "$resource" == namespace/* ]]; then
        namespace="${resource#namespace/}"
        resource="namespace"
    fi

    if [[ "$resource" == "namespace" ]] && [[ -n "$namespace" ]]; then
        # Check if namespace exists first
        if ! $KUBECTL get namespace "$namespace" &>/dev/null; then
            echo "DEBUG: Namespace $namespace does not exist, skipping"
            return 0
        fi
        echo "DEBUG: kubectl_inspect: resource type as ${resource} in namesapce ${namespace}"
        local ns_dir="${dest_dir}/namespaces/${namespace}"
        mkdir -p "${ns_dir}"

        # Get namespace yaml
        $KUBECTL get namespace "$namespace" -o yaml > "${ns_dir}/${namespace}.yaml" 2>/dev/null

        # Auto-discover all namespaced resources
        auto_discover_resources "true" "${ns_dir}" "${namespace}"

        # Get container logs from pod
        for pod in $($KUBECTL get pods -n "$namespace" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null); do
            local pod_dir="${ns_dir}/pods/${pod}"
            mkdir -p "${pod_dir}"
            $KUBECTL get pod "$pod" -n "$namespace" -o yaml > "${pod_dir}/${pod}.yaml" 2>/dev/null

            # Get logs for each container
            for container in $($KUBECTL get pod "$pod" -n "$namespace" -o jsonpath='{.spec.containers[*].name}' 2>/dev/null); do
                mkdir -p "${pod_dir}/${container}/logs"
                # shellcheck disable=SC2086,SC2154
                $KUBECTL logs "$pod" -n "$namespace" -c "$container" $log_collection_args > "${pod_dir}/${container}/logs/current.log" 2>/dev/null || true
                # shellcheck disable=SC2086
                $KUBECTL logs "$pod" -n "$namespace" -c "$container" --previous $log_collection_args > "${pod_dir}/${container}/logs/previous.log" 2>/dev/null || true
            done
        done
        return 0
    elif [[ -n "$namespace" ]]; then
        # Collect specific resource type in namespace
        echo "DEBUG: kubectl_inspect: resource type as ${resource} in namespace ${namespace}"
        local res_name="${resource##*/}"  # extract name after last /
        local res_dir="${dest_dir}/namespaces/${namespace}/${resource}"
        mkdir -p "${res_dir}"
        $KUBECTL get "$resource" -n "$namespace" -o yaml > "${res_dir}/${res_name}.yaml" 2>/dev/null || true
        return 0
    fi
}

# Auto-discover and collect all cluster-scoped resources
function collect_cluster_scoped_resources() {
    local dest_dir="${DST_DIR}/cluster-scoped-resources"
    auto_discover_resources "false" "${dest_dir}"
}

# run gather in the namespaces one by one, also collecting custom resources
function run_k8sgather() {
    local namespaces="$1"
    shift
    local resources=("${DEFAULT_RESOURCES[@]}" "$@")

    for ns in $namespaces; do
        # Only collect specific resource types, not entire namespace
        for resource in "${resources[@]}"; do
            kubectl_inspect "$resource" "$ns" 2>/dev/null
        done
    done
}

# Detect xKS distro
function detect_k8s_distro() {
    local distro="other" # the rest from ocp, cks and aks for now.

    # Determine which command to use (take oc proceed at this stage does not really matter which one to use)
    local cmd
    if command -v oc &> /dev/null; then
        cmd="oc"
    elif command -v kubectl &> /dev/null; then
        cmd="kubectl"
    else # This should never get hit
        echo "ERROR: Neither 'oc' nor 'kubectl' command found. Cannot proceed." >&2
        exit 1
    fi

    local kernel_version os_image provider_id
    kernel_version=$(${cmd} get nodes -o jsonpath='{.items[0].status.nodeInfo.kernelVersion}' 2>/dev/null) # for CKS
    os_image=$(${cmd} get nodes -o jsonpath='{.items[0].status.nodeInfo.osImage}' 2>/dev/null)  # for OCP
    provider_id=$(${cmd} get nodes -o jsonpath='{.items[0].spec.providerID}' 2>/dev/null) # for AKS

    # Check for OpenShift first (catches ROSA and ARO)
    if echo "$os_image" | grep -q "Red Hat Enterprise Linux CoreOS"; then
        distro="ocp"
    # Check API resources for OpenShift (fallback)
    elif ${cmd} api-resources 2>/dev/null | grep -q "route.openshift.io"; then
        distro="ocp"
    # Check kernel version for CoreWeave
    elif echo "$kernel_version" | grep -qi "coreweave"; then
        distro="cks"
    # Check for Azure Kubernetes Service (after OCP to avoid ARO confusion)
    elif echo "$provider_id" | grep -q "^azure://"; then
        distro="aks"
    fi

    echo "$distro"
}