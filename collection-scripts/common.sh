export DST_DIR="must-gather"

# run must-gather in the namespaces one by one
function run_mustgather() {
    for ns in $1; do
        oc adm inspect "namespace/$ns" --all-namespaces --dest-dir "$DST_DIR" || echo "Error inspecting namespace/$ns"
    done
}

# get the list of namespaces where defined resources exist
function get_all_namespace() {
    local nslist
    for kind in "$1"; do
        nslist+=$(oc get "$kind" --all-namespaces -o=jsonpath='{range .items[*]}{.metadata.namespace}{"\n"}{end}')
    done
    echo $(uniq_list "$nslist")
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
  [[ z == z"${version}" && z != z"${csv_name}" ]] && version=$(oc get csv $(oc get csv|grep rhods|awk '{print $1}') -o json|jq .spec.version |xargs)

  # if version not found, get version from rhods operator pod's container
  operator_name=$(oc get pod -n redhat-ods-operator --ignore-not-found |grep redhat-ods-operator |awk '{print $1}')
  [[ z != z"${operator_name}" ]] && version=$(oc exec ${operator_name} -n redhat-ods-operator -c manager -- env|grep OPERATOR_CONDITION_NAME|awk -F'=' '{print $2}'| sed -n -r -e 's/.*([[:digit:]]+\.[[:digit:]]+\.[[:digit:]]+(:?\.[[:digit:]])?(:?-[^@]+)?).*/\1/p')

  # if version still not found, use Unknown
  [[ z == z"${version}" ]] && version="Unknown"

  echo ${version}
}
