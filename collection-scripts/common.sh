#!/bin/bash
# shellcheck disable=SC2034,SC2086,SC2001,SC2068
# be careful of 2068, oc is very sensitive with "" on variables with error error: there is no need to specify a resource type as a separate argument when passing arguments in resource/name form (e.g. 'oc get resource/<resource_name>' instead of 'oc get resource resource/<resource_name>'

export DST_DIR="must-gather"

# run must-gather in the namespaces one by one
function run_mustgather() {
    for ns in $@; do
        oc adm inspect $log_collection_args namespace/$ns --dest-dir "$DST_DIR" || echo "Error inspecting namespace/$ns"
    done
}

# get the list of namespaces where defined resources exist
function get_all_namespace() {
    local nslist
    for kind in "$@"; do
        nslist+=$(oc get "$kind" --all-namespaces -o jsonpath='{range .items[*]}{.metadata.namespace}{" "}{end}')
    done
    uniq_list "$nslist"
}

# remove dupplicated namespaces
function uniq_list() {
    echo "$@" | sort -u
}

# get the version of RHOAI operator
function rhoai_version() {
  version=''

  # get version from RHOAI csv
  csv_name=$(oc get clusterserviceversions| awk '/rhods/{print $1}')
  if [ -z "${version}" ] && [ -n "${csv_name}" ]; then
	version=$(oc get csv/"${csv_name}" -o json | jq .spec.version | xargs)
  fi

  # read label from operator deployment
  if [ -z "${version}" ]; then
    version=$(oc get deployment/rhods-operator -n redhat-ods-operator --output=json | jq '.metadata.labels."olm.owner"')
  fi
 
  # if version still not found, use Unknown
  if [ -z "${version}" ]; then
	version="Unknown"
  fi
  
  echo "${version}"
}

function get_operator_resource() {
    CR=$(oc get "$1" --no-headers | awk '{print $1}')
    oc adm inspect $log_collection_args "$1"/"$CR" --dest-dir "$DST_DIR" || echo "Error collecting info from ${CR}"
}


# cherrypick from https://github.com/openshift/must-gather/blob/4b03e40e374c2e8096d6043bcfd1c23dd4cd9d0b/collection-scripts/common.sh#L19
# even we do not run "oc adm node-logs" in RHOAI
get_log_collection_args() {
	# validation of MUST_GATHER_SINCE and MUST_GATHER_SINCE_TIME is done by the
	# caller (oc adm must-gather) so it's safe to use the values as they are.
	log_collection_args=""

	if [ -n "${MUST_GATHER_SINCE:-}" ]; then
		log_collection_args=--since="${MUST_GATHER_SINCE}"
	fi
	if [ -n "${MUST_GATHER_SINCE_TIME:-}" ]; then
		log_collection_args=--since-time="${MUST_GATHER_SINCE_TIME}"
	fi

	# oc adm node-logs `--since` parameter is not the same as oc adm inspect `--since`.
	# it takes a simplified duration in the form of '(+|-)[0-9]+(s|m|h|d)' or
	# an ISO formatted time. since MUST_GATHER_SINCE and MUST_GATHER_SINCE_TIME
	# are formatted differently, we re-format them so they can be used
	# transparently by node-logs invocations.
	# in RHOAI we do not use below logic for now
	node_log_collection_args=""

	if [ -n "${MUST_GATHER_SINCE:-}" ]; then
		since=$(echo "${MUST_GATHER_SINCE:-}" | sed 's/\([0-9]*[dhms]\).*/\1/')
		node_log_collection_args=--since="-${since}"
	fi
	if [ -n "${MUST_GATHER_SINCE_TIME:-}" ]; then
		iso_time=$(echo "${MUST_GATHER_SINCE_TIME}" | sed 's/T/ /; s/Z//')
		node_log_collection_args=--since="${iso_time}"
	fi
}