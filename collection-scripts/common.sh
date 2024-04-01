#!/bin/bash
# shellcheck disable=SC2034,SC2086,SC2001

export DST_DIR="must-gather"

# run must-gather in the namespaces one by one
function run_mustgather() {
    for ns in "$@"; do
        oc adm inspect "${log_collection_args}" "namespace/$ns" --all-namespaces --dest-dir "$DST_DIR" || echo "Error inspecting namespace/$ns"
    done
}

# get the list of namespaces where defined resources exist
function get_all_namespace() {
    local nslist
    for kind in "$@"; do
        nslist+=$(oc get "$kind" --all-namespaces -o=jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}')
    done
    uniq_list "$nslist"
}

# remove dupplicated namespaces
function uniq_list() {
    echo "$@" | sort -u
}

# get the version of rhoai operator
function version() {
  version=''

  # get version from rhoai csv
  csv_name=$(oc get csv|grep rhods|awk '{print $1}')
  [[ z == z"${version}" && z != z"${csv_name}" ]] && version=$(oc get csv "$(oc get csv|grep rhods|awk '{print $1}')" -o json|jq .spec.version |xargs)

  # if version not found, get version from rhods operator pod's container
  operator_name=$(oc get pod -n redhat-ods-operator --ignore-not-found |grep redhat-ods-operator |awk '{print $1}')
  [[ z != z"${operator_name}" ]] && version=$(oc exec ${operator_name} -n redhat-ods-operator -c manager -- env|grep OPERATOR_CONDITION_NAME|awk -F'=' '{print $2}'| sed -n -r -e 's/.*([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+(:?\.[[:digit:]])?(:?-[^@]+)?).*/\1/p')

  # if version still not found, use Unknown
  [[ z == z"${version}" ]] && version="Unknown"
  echo "${version}"
}

function get_operator_resource() {
    CR=$(oc get "$1" --no-headers | awk '{print $1}')
    oc adm inspect "${log_collection_args}" "$1"/"$CR" --dest-dir "$DST_DIR" || echo "Error collecting info from ${CR}"
}


# cherrypick from https://github.com/openshift/must-gather/blob/4b03e40e374c2e8096d6043bcfd1c23dd4cd9d0b/collection-scripts/common.sh#L19
# even we do not run "oc adm node-logs" in rhoai
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