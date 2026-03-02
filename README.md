# must-gather for Red Hat OpenShift AI

The must-gather script allows a cluster admin to collect information about various key resources and namespaces
for Red Hat OpenShift AI.

## Data Collected

The must-gather script currently collects data from following default namespaces

- redhat-ods-operator
- rhods-notebooks
- redhat-ods-applications
- redhat-ods-monitoring
- rhoai-model-registries

and datasciencecluster and dscinitialization instances from cluster

This script also collects data from all the namespaces that has

- `datasciencepipelinesapplications` `scheduledworkflow` `applications` `clusterworkflowtemplates` `cronworkflows` `viewers` `workfloweventbindings` `workflows` `workflowtaskresults` `workflowtemplates` `workflowtasksets` for AI Pipeline (Previously called Data Science Pipeline) component
- `rayclusters` `rayjobs` `rayservices` for KubeRay component
- `clusterqueues` `localqueues` `multikueueclusters` `multikueueconfigs` `provisioningrequestconfigs` `resourceflavors` `workloads` `workloadpriorityclasses` for Kueue component
- `mpijobs` `mxjobs` `paddlejobs` `pytorchjob` `tfjob` `xgboostjob`  for Kubeflow Training Operator
- `inferenceservices` `inferencegraphs` `"trainedmodels` `servingruntimes` `clusterstoragecontainers` `predictors` for Kserve component
- `notebooks` `imagestreams` for Workbench component
- `modelregistries` for Model Registry component
- `featurestores` for Feast Operator
- `llamastackdistributions` for Llama-stack Operator
- `mlflows` for MLflow Operator

## Usage

Refer to KCS: https://access.redhat.com/solutions/7061604 

To collect all for RHOAI release 3.0

```
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.0
```

To collect for only one component use env variable COMPONENT.
Full list of supported components see table below:

| COMPONENT value | Comments                   |
|-----------------|----------------------------|
| dashboard       | Dashboard                  |
| dsp             | AI Pipeline (previously: Data Science Pipeline)|
| kuberay         | KubeRay                    |
| kueue           | Kueue                      |
| kfto            | Kubeflow Training Operator |
| kserve          | Kserve                     |
| workbench       | Workbench                  |
| modelregistry   | Model Registry             |
| trustyai        | TrustyAI                   |
| feastoperator   | Feast Operator             |
| llamastack      | Llama-stack Operator       |
| mlflow          | MLflow Operator            |
| llm-d           | LLM-D (auto-enabled for xKS)|

for example to 'kserve':

```
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.0 -- "export COMPONENT=kserve; /usr/bin/gather"
```

To collect logs after a specific date (RFC3339). This feature only support oc 4.16+
Defaults to all logs.
If this value is in the future, no logs will be returned.
If this value precedes the time a pod was started, only logs since the pod start will be returned.
Only one of MUST_GATHER_SINCE_TIME / MUST_GATHER_SINCE may be used

```cmd
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.0 --since-time=2024-05-02T14:01:23Z
```

To collect logs newer than a relative duration like 5s, 2m, or 3h. This feature only support oc 4.16+
Defaults to all logs.
Only one of MUST_GATHER_SINCE_TIME / MUST_GATHER_SINCE may be used

```cmd
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.0 --since=3h
```

If you have enabled customized namespaces for installation, below env. variable need to be configured when running "oc adm must-gather", example:
```
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.0 -- "export OPERATOR_NAMESPACE=<your-operator-namespace>;export APPLICATIONS_NAMESPACE=<your-application-namespace>; /usr/bin/gather"
```

To enable workload-variant-autoscaler for llm-d on xKS (optional):
```
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.4 -- "export ENABLE_WVA=true; /usr/bin/gather"
```

For llm-d running on AKS with Azure Managed Prometheus:
```
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.4 -- "export AKS_MONITORING_TYPE=managed; /usr/bin/gather"
```

## Usage on Non-OpenShift Kubernetes (xKS)

For managed Kubernetes platforms like **CoreWeave (CKS)** and **Azure Kubernetes Service (AKS)**, must-gather can collect LLM-D inference-related resources.

The script automatically detects:
- **CKS** (CoreWeave Kubernetes) - via kernel version
- **AKS** (Azure Kubernetes Service) - via provider ID
- **OCP** (OpenShift) - via CoreOS image or OpenShift APIs

### Quick Start

**Step 1: Create RBAC (requires cluster admin)**

```bash
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: must-gather
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: must-gather-sa
  namespace: k8s-gather
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: must-gather-reader
rules:
  - apiGroups: ["*"]
    resources: ["*"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: must-gather-reader-binding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: must-gather-reader
subjects:
  - kind: ServiceAccount
    name: must-gather-sa
    namespace: must-gather
EOF
```

**Step 2: Run must-gather as a Job**

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: must-gather-job
  namespace: must-gather
spec:
  template:
    spec:
      serviceAccountName: must-gather-sa
      containers:
      - name: gather
        image: quay.io/wenzhou/must-gather:latest
        command: ["/bin/bash", "-c", "cd /tmp && /usr/bin/gather && sleep 600"]
      restartPolicy: Never
EOF
```

**Step 3: Retrieve collected data**

```bash
# Get pod name
POD_NAME=$(kubectl get pods -n must-gather -l job-name=must-gather-job -o jsonpath='{.items[0].metadata.name}')

# Wait for collection to complete by checking for completion message in logs
echo "Waiting for must-gather to complete..."
until kubectl logs $POD_NAME -n must-gather 2>/dev/null | grep -q "DEBUG: LLM-D resource collection completed"; do
  sleep 10
done
echo "Collection completed!"

# Copy collected data to local machine
kubectl cp must-gather/$POD_NAME:/tmp/must-gather ./must-gather.local.$(date +%s)
```

### Optional Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_WVA` | `false` | Enable workload-variant-autoscaler collection |
| `AKS_MONITORING_TYPE` | `self-hosted` | `managed` for Azure Managed Prometheus, `self-hosted` for kube-prometheus-stack |

**Example with WVA enabled:**
```bash
env:
- name: ENABLE_WVA
  value: "true"
```

**Example for AKS with Azure Managed Prometheus:**
```bash
env:
- name: AKS_MONITORING_TYPE
  value: "managed"
```

## Developer Guide

To build custom image quay.io/myname/must-gather:1.2.3, can set GATHER_IMG and/or GATHER_IMG_VERSION
by default GATHER_IMG is set to 'quay.io/$USER_NAME/must-gather' and GATHER_IMG_VERSION is 'dev'

```
export GATHER_IMG=quay.io/myname/must-gather
export GATHER_IMG_VERSION=1.2.3
make build-and-push-must-gather

```

To collect data for custom repositories for Open Data Hub set the following variables inside must-gather:

```
export OPERATOR_NAMESPACE=<name-for-operator-namespace>
export NOTEBOOKS_NAMESPACE=<name-for-notebooks-namespace>
export MONITORING_NAMESPACE=<name-for-monitoring-namespace>
export APPLICATIONS_NAMESPACE=<name-for-applications-namespace>
export MODEL_REGISTRIES_NAMESPACE=<name-for-model-registries-namespace>
export MAAS_NAMESPACE=<name-for-maas-namespace>

```
