#!/bin/bash
# shellcheck disable=SC2154,SC1091,SC2086,SC2155
export SCRIPT_DIR="$(dirname "$0")"

source "${SCRIPT_DIR}/common.sh"

# Detect Kubernetes distribution
source "${SCRIPT_DIR}/llm-d/xks_util.sh"
export K8S_DISTRO=$(detect_k8s_distro)

echo "Detected Kubernetes distribution: ${K8S_DISTRO}"

# Set KUBECTL based on distribution
if [[ "${K8S_DISTRO}" == "ocp" ]]; then
    export KUBECTL="oc"
else
    export KUBECTL="kubectl"
fi

# Get log collection arguments (--since, --since-time) for both oc adm inspect and kubectl logs
get_log_collection_args

# Define common namespaces (used by both OpenShift and xKS)
export OPERATOR_NS=${OPERATOR_NAMESPACE:-redhat-ods-operator}
export APPLICATIONS_NS=${APPLICATIONS_NAMESPACE:-redhat-ods-applications}
export HELM_CHART_NS=${RHAI_HELM_CHART_NS:-rhai-gitops}
export CLOUDMANAGER_NS=${RHAI_CLOUDMANAGER_NS:-rhai-cloudmanager-system}

# OpenShift-specific logic - for RHOAI
if [[ "${K8S_DISTRO}" == "ocp" ]]; then
    echo "=========================================="
    echo "DEBUG: OpenShift detected. Running RHOAI-specific collection..."
    echo "DEBUG: Using KUBECTL=${KUBECTL}"
    echo "=========================================="

    # define default namespaces
    # Get operator namespace: use env var if set, otherwise auto-detect from subscription
    if [ -n "${OPERATOR_NAMESPACE}" ]; then
        OPERATOR_NS="${OPERATOR_NAMESPACE}"
    else
        # auto-detect based on operator name
        get_operator_ns "rhods-operator"
        OPERATOR_NS="${operator_ns}"
    fi

    NOTEBOOKS_NS=${NOTEBOOK_NAMESPACE:-rhods-notebooks}
    MONITORING_NS=${MONITORING_NAMESPACE:-redhat-ods-monitoring}
    MODELREG_NS=${MODEL_REGISTRIES_NAMESPACE:-rhoai-model-registries}
    KUADRANT_NS="kuadrant-system"
    # dependent operator namespace
    GW_NS=${GW_NS:-openshift-ingress}

    # generate /must-gather/version file with RHOAI version
    echo "red-hat-data-services/must-gather" > "$DST_DIR/version"
    rhoai_version >> "$DST_DIR/version"

    oc adm inspect $log_collection_args "namespace/$OPERATOR_NS" --dest-dir="$DST_DIR" || echo "Error getting logs from ${OPERATOR_NS}"
    oc adm inspect $log_collection_args "namespace/$MONITORING_NS" --dest-dir="$DST_DIR"  || echo "Error getting logs from ${MONITORING_NS}"
    oc adm inspect $log_collection_args "namespace/$APPLICATIONS_NS" --dest-dir="$DST_DIR"  || echo "Error getting logs from ${APPLICATIONS_NS}"
    oc adm inspect $log_collection_args "namespace/$NOTEBOOKS_NS" --dest-dir="$DST_DIR" || echo "Error getting logs from ${NOTEBOOKS_NS}"
    oc adm inspect $log_collection_args "namespace/$MODELREG_NS" --dest-dir="$DST_DIR"  || echo "Error getting logs from ${MODELREG_NS}"
    oc adm inspect $log_collection_args "namespace/$GW_NS" --dest-dir="$DST_DIR"  || echo "Error getting logs from ${GW_NS}"
    oc adm inspect $log_collection_args "namespace/$KUADRANT_NS" --dest-dir="$DST_DIR"  || echo "Error getting logs from ${KUADRANT_NS}"
    oc adm inspect $log_collection_args "namespace/$HELM_CHART_NS" --dest-dir="$DST_DIR"  || echo "Error getting logs from ${HELM_CHART_NS}"

    echo "Collecting Helm release information..."
    export HELM_RELEASE_NAME=${RHAI_HELM_RELEASE_NAME:-rhoai}
    collect_helm_releases "$HELM_CHART_NS" "$HELM_RELEASE_NAME"
    # add DSCI, DSC, Auth and service/component/infra CRs
    resources=(
      "dscinitialization"
      "datasciencecluster"
      "auths.services.platform.opendatahub.io"
      "monitorings.services.platform.opendatahub.io"
      "gatewayconfigs.services.platform.opendatahub.io"
      "hardwareprofiles.infrastructure.opendatahub.io"
      "dashboards.components.platform.opendatahub.io"
      "datasciencepipelines.components.platform.opendatahub.io"
      "feastoperators.components.platform.opendatahub.io"
      "kserves.components.platform.opendatahub.io"
      "kueues.components.platform.opendatahub.io"
      "modelcontrollers.components.platform.opendatahub.io"
      "modelregistries.components.platform.opendatahub.io"
      "rays.components.platform.opendatahub.io"
      "trainingoperators.components.platform.opendatahub.io"
      "trustyais.components.platform.opendatahub.io"
      "workbenches.components.platform.opendatahub.io"
      "llamastackoperators.components.platform.opendatahub.io"
      "mlflowoperators.components.platform.opendatahub.io"
      "mutatingwebhookconfigurations.admissionregistration.k8s.io"
      "validationwebhookconfigurations.admissionregistration.k8s.io"
      "validatingadmissionpolicy"
      "validatingadmissionpolicybinding"
      "gatewayclasses"
      "trainers.components.platform.opendatahub.io"
      "sparkoperators.components.platform.opendatahub.io"
      "agentsoperators.components.platform.opendatahub.io"
    )
    get_operator_resource "${resources[@]}"

    # set component or default based on distribution
    # For non-OpenShift, we only run with llm-d; for OpenShift, default to all
    component=${COMPONENT:-all}
else
    if [ -n "${OPERATOR_NAMESPACE}" ]; then
        OPERATOR_NS="${OPERATOR_NAMESPACE}"
    else
        OPERATOR_NS="redhat-ods-operator"
    fi

    echo "Collecting Helm release information..."
    export HELM_RELEASE_NAME=${RHAI_HELM_RELEASE_NAME:-rhaii}
    collect_helm_releases "$HELM_CHART_NS" "$HELM_RELEASE_NAME"
    resources=()
    case "$K8S_DISTRO" in
        aks) resources+=("azurekubernetesengines.infrastructure.opendatahub.io") ;;
        cks) resources+=("coreweavekubernetesengines.infrastructure.opendatahub.io") ;;
        eks) resources+=("awskubernetesengines.infrastructure.opendatahub.io") ;;
    esac
    component="llm-d"
fi

echo "=========================================="
echo "DEBUG: Component=${component}"
echo "=========================================="

case "$component" in
    "dsp")
        "${SCRIPT_DIR}/gather_data_science_pipelines.sh"
        ;;
    "kserve")
        "${SCRIPT_DIR}/gather_serving.sh"
        ;;
    "dashboard")
        "${SCRIPT_DIR}/gather_dashboard.sh"
        ;;
    "workbench")
        "${SCRIPT_DIR}/gather_notebooks.sh"
        ;;
    "kuberay")
        "${SCRIPT_DIR}/gather_kuberay.sh"
        ;;
    "kueue")
        "${SCRIPT_DIR}/gather_kueue.sh"
        ;;
    "kfto")
        "${SCRIPT_DIR}/gather_kfto.sh"
        ;;
    "modelregistry")
        "${SCRIPT_DIR}/gather_mr.sh"
        ;;
    "trustyai")
        "${SCRIPT_DIR}/gather_trustyai.sh"
        ;;
    "feastoperator")
        "${SCRIPT_DIR}/gather_feastoperator.sh"
        ;;
    "llamastack")
        "${SCRIPT_DIR}/gather_lls.sh"
        ;;
    "mlflow")
        "${SCRIPT_DIR}/gather_mlflow.sh"
        ;;
    "sparkoperator")
        "${SCRIPT_DIR}/gather_sparkoperator.sh"
        ;;
    "maas")
        "${SCRIPT_DIR}/gather_models_as_a_service.sh"
        ;;
    "agentsoperator")
        "${SCRIPT_DIR}/gather_agentsoperator.sh"
        ;;
    "llm-d")
        "${SCRIPT_DIR}/llm-d/gather_llmd.sh"
        # WVA is optional, controlled by ENABLE_WVA env var (default: false)
        if [[ "${ENABLE_WVA:-false}" == "true" ]]; then
            "${SCRIPT_DIR}/llm-d/gather_wva.sh"
        fi
        # Batch gateway is optional, controlled by ENABLE_BATCH_GATEWAY env var (default: false)
        if [[ "${ENABLE_BATCH_GATEWAY:-false}" == "true" ]]; then
            "${SCRIPT_DIR}/llm-d/gather_batch_gateway.sh"
        fi
        ;;
    *) # for all except llm-d

        # Track PIDs and job names for error reporting
        declare -A job_pids
        declare -a failed_jobs

        echo "Starting parallel data collection..."

        # Start all gather operations in background and track PIDs
        "${SCRIPT_DIR}/gather_data_science_pipelines.sh" & job_pids[$!]="dsp"
        "${SCRIPT_DIR}/gather_serving.sh" & job_pids[$!]="kserve"
        "${SCRIPT_DIR}/gather_notebooks.sh" & job_pids[$!]="workbench"
        "${SCRIPT_DIR}/gather_kuberay.sh" & job_pids[$!]="kuberay"
        "${SCRIPT_DIR}/gather_kueue.sh" & job_pids[$!]="kueue"
        "${SCRIPT_DIR}/gather_kfto.sh" & job_pids[$!]="kfto"
        "${SCRIPT_DIR}/gather_mr.sh" & job_pids[$!]="modelregistry"
        "${SCRIPT_DIR}/gather_trustyai.sh" & job_pids[$!]="trustyai"
        "${SCRIPT_DIR}/gather_feastoperator.sh" & job_pids[$!]="feastoperator"
        "${SCRIPT_DIR}/gather_lls.sh" & job_pids[$!]="llamastack"
        "${SCRIPT_DIR}/gather_mlflow.sh" & job_pids[$!]="mlflow"
        "${SCRIPT_DIR}/gather_sparkoperator.sh" & job_pids[$!]="spark"
        "${SCRIPT_DIR}/gather_models_as_a_service.sh" & job_pids[$!]="maas"
        "${SCRIPT_DIR}/gather_agentsoperator.sh" & job_pids[$!]="agentsoperator"

        echo "Waiting for ${#job_pids[@]} jobs to complete..."

        # Wait for all jobs and mark failed one to later report
        for pid in "${!job_pids[@]}"; do
            if ! wait "$pid"; then
                failed_jobs+=("${job_pids[$pid]}")
            fi
        done
        ;;
esac

# wait for all background jobs to complete
wait

# force disk flush to ensure that all data gathered is accessible in the copy container
sync

# Generate collection summary report
echo "=========================================="
echo "Must-Gather Collection Summary"
echo "=========================================="
echo "Timestamp: $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
echo "Kubernetes Distribution: ${K8S_DISTRO}"
echo "Component: ${component}"
echo "Destination: ${DST_DIR}"

if [ -n "${failed_jobs[*]}" ]; then
    echo ""
    echo "Status: (${#failed_jobs[@]} failures)"
    echo "Failed components:"
    printf '  - %s\n' "${failed_jobs[@]}"
else
    echo ""
    echo "Status: SUCCESS"
fi

echo "=========================================="
echo "DEBUG: Must-gather collection completed"
echo "=========================================="
