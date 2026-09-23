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

- `datasciencepipelinesapplications` `scheduledworkflows` `clusterworkflowtemplates` `cronworkflows` `workfloweventbindings` `workflows` `workflowtaskresults` `workflowtemplates` `workflowtasksets` `workflowartifactgctasks` for AI Pipeline (Previously called Data Science Pipeline) component
- `rayclusters` `rayjobs` `rayservices` for KubeRay component
- `admissionchecks` `cohorts` `clusterqueues` `localqueues` `multikueueclusters` `multikueueconfigs` `provisioningrequestconfigs` `resourceflavors` `workloads` `workloadpriorityclasses` for Kueue component
- `mpijobs` `paddlejobs` `pytorchjob` `tfjob` `xgboostjob` `jaxjobs` `jobsetoperators` `trainjobs.trainer.kubeflow.org` `trainingruntimes.trainer.kubeflow.org` `clustertrainingruntimes.trainer.kubeflow.org` for Kubeflow Training Operator
- `inferenceservices` `inferencegraphs` `trainedmodels` `servingruntimes` `clusterstoragecontainers` `predictors` `localmodelnodegroups` `authconfigs` `authorinos` `authpolicies.kuadrant.io` `accounts.nim.opendatahub.io` `llminferenceserviceconfigs` `llminferenceservices` `inferencepools` `kserves.components.platform.opendatahub.io` for Kserve component
- `leaderworkersets.leaderworkerset.x-k8s.io` `disaggregatedsets.disaggregatedset.x-k8s.io` `disaggregatedsetrolescalers.disaggregatedset.x-k8s.io` for LWS; `leaderworkersetoperators.operator.openshift.io` for the LWS Operator on OCP (collected by the LWS dependency collector when LLM-D runs)
- `modelexpressservers.modelexpress.opendatahub.io` `modelmetadatas.modelexpress.nvidia.com` `modelcacheentries.modelexpress.nvidia.com` for ModelExpress (included with KServe on OCP; opt-in on xKS)
- `notebooks` `imagestreams` for Workbench component
- `modelregistries.modelregistry.opendatahub.io` for Model Registry component
- `featurestores` for Feast Operator
- `mlflows.mlflow.opendatahub.io` for MLflow Operator
- `sparkapplications` `scheduledsparkapplications` `sparkconnects` for Spark Operator
- `aigateways.components.platform.opendatahub.io` `aiguardrails.inference.opendatahub.io` `externalmodels.inference.opendatahub.io` `externalproviders.inference.opendatahub.io` for AI Gateway
- `aitenants.maas.opendatahub.io` `configs.maas.opendatahub.io` `externalmodels.maas.opendatahub.io` `maasauthpolicies.maas.opendatahub.io` `maasmodelrefs.maas.opendatahub.io` `maassubscriptions.maas.opendatahub.io` `maastenantconfigs.maas.opendatahub.io` `tenants.maas.opendatahub.io` `ratelimitpolicies.kuadrant.io` `kuadrants.kuadrant.io` `tokenratelimitpolicies.kuadrant.io` for MaaS (included by default on OCP; opt-in on xKS with `ENABLE_MAAS=true`)
- `llmbatchgateways.batch.llm-d.ai` for Batch Gateway (included by default on OCP; opt-in on xKS with `ENABLE_BATCH_GATEWAY=true`)
- `mcpservers` for MCP Lifecycle Operator
- `ogxservers` for OGX Operator

## Usage on OpenShift

Refer to KCS: https://access.redhat.com/solutions/7061604 

To collect all for RHOAI release 3.6

```
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.6.0
```

To collect for only one component use env variable COMPONENT.
Full list of supported components see table below:

| COMPONENT value | Comments                                        |
|-----------------|-------------------------------------------------|
| dashboard       | Dashboard                                       |
| dsp             | AI Pipeline (previously: Data Science Pipeline) |
| kuberay         | KubeRay                                         |
| kueue           | Kueue                                           |
| kfto            | Kubeflow Training Operator                      |
| kserve          | KServe and LLM-D resources; LLM-D runs the LWS dependency collector |
| workbench       | Workbench                                       |
| modelregistry   | Model Registry                                  |
| trustyai        | TrustyAI                                        |
| feastoperator   | Feast Operator                                  |
| mlflow          | MLflow Operator                                 |
| sparkoperator   | Spark Operator                                  |
| aigateway       | AI Gateway; optional Batch Gateway and MaaS     |
| mcplo           | MCP Lifecycle Operator                          |
| ogx             | OGX Operator                                    |

for example to 'kserve':

```
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.6.0 -- "export COMPONENT=kserve; gather"
```

To collect logs after a specific date (RFC3339). This feature only support oc 4.16+
Defaults to all logs.
If this value is in the future, no logs will be returned.
If this value precedes the time a pod was started, only logs since the pod start will be returned.
Only one of MUST_GATHER_SINCE_TIME / MUST_GATHER_SINCE may be used

```cmd
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.6.0 --since-time=2024-05-02T14:01:23Z
```

To collect logs newer than a relative duration like 5s, 2m, or 3h. This feature only support oc 4.16+
Defaults to all logs.
Only one of MUST_GATHER_SINCE_TIME / MUST_GATHER_SINCE may be used

```cmd
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.6.0 --since=3h
```

If you have enabled customized namespaces for installation, below env. variable need to be configured when running "oc adm must-gather", example:
```
oc adm must-gather --image=registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.6.0 -- "export OPERATOR_NAMESPACE=<your-operator-namespace>;export APPLICATIONS_NAMESPACE=<your-application-namespace>; gather"
```

On OpenShift, KServe collects ModelExpress, and its LLM-D collector gathers LWS resources. AI Gateway collects MaaS and Batch Gateway by default; no `ENABLE_*` flags are needed.

## Usage on Non-OpenShift Kubernetes (xKS)

On xKS, the default gather runs KServe and LLM-D; LLM-D invokes the LWS dependency collector. AI Gateway also runs by default. Use `ENABLE_MODELEXPRESS=true`, `ENABLE_BATCH_GATEWAY=true`, and `ENABLE_MAAS=true` to opt into those additional resources.

Supported platforms:
- **CKS** (CoreWeave Kubernetes)
- **AKS** (Azure Kubernetes Service)
- **EKS** (Amazon Elastic Kubernetes Service)
- **OpenShift** with RHAII - see [Usage on OpenShift](#usage-on-openshift) above

> **Note for OpenShift RHAII Users:** The default full OpenShift gather collects all components. The KServe component includes LLM-D resource collection.
> The Kubernetes Job approach below is primarily intended for non-OpenShift platforms (CKS, AKS, EKS).

> **Custom Namespaces:** If you used custom namespaces, add the appropriate environment variables to the Job spec. See the [Developer Guide](#developer-guide) section for the complete list of namespace variables.

### Quick Start

**Step 1: Create RBAC**

```bash
# Set namespace
NAMESPACE=must-gather

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: must-gather-sa
  namespace: ${NAMESPACE}
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
    namespace: ${NAMESPACE}
EOF
```

**Step 2: Authenticate to registry and create image pull secret**

```bash
# Authenticate to the registry
podman login registry.redhat.io

# Verify you can pull the must-gather image
podman pull registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.6.0

# Create Kubernetes secret from podman auth
# This uses ~/.config/containers/auth.json for podman (persistent across sessions)
# For docker users, use ~/.docker/config.json instead
kubectl create secret generic redhat-pull-secret \
  --from-file=.dockerconfigjson=${HOME}/.config/containers/auth.json \
  --type=kubernetes.io/dockerconfigjson \
  -n ${NAMESPACE}
```

**Step 3: Run must-gather as a Job**

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: must-gather-job
  namespace: ${NAMESPACE}
spec:
  template:
    spec:
      serviceAccountName: must-gather-sa
      imagePullSecrets:
      - name: redhat-pull-secret
      containers:
      - name: gather
        image: registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.6.0
        command: ["/bin/bash", "-c", "cd /tmp && gather && sleep 600"]
      restartPolicy: Never
EOF
```

**Step 4: Retrieve collected data**

```bash

# Get pod name
POD_NAME=$(kubectl get pods -n $NAMESPACE -l job-name=must-gather-job -o jsonpath='{.items[0].metadata.name}')

# Optional: to follow pod logs
kubectl logs -f $POD_NAME -n $NAMESPACE

# Wait for collection to complete by checking for completion message in logs
echo "Waiting for must-gather to complete..."
until kubectl logs -l job-name=must-gather-job -n $NAMESPACE 2>&1 | tail -5 | grep -q "Musts-gather collection completed"; do sleep 10; done
echo "Collection completed!"

# Copy collected data to local machine
# IMPORTANT: Do this within 10 minutes! The pod sleeps for 10 minutes after collection,
# then exits. If you need more time, increase the sleep value in the Job spec.
kubectl cp $NAMESPACE/$POD_NAME:/tmp/must-gather ./must-gather.local.$(date +%s)
```

**Step 4: Clean up resources**

```bash
# Delete the Job (reuse NAMESPACE variable from Step 3)
kubectl delete job must-gather-job -n $NAMESPACE

# Optional: Delete namespace and RBAC (if no longer needed)
kubectl delete namespace $NAMESPACE
kubectl delete clusterrolebinding must-gather-reader-binding
kubectl delete clusterrole must-gather-reader
```

### Optional Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `ENABLE_MODELEXPRESS` | `false` on xKS; always on OCP | Include ModelExpress with KServe |
| `ENABLE_MAAS` | `false` on xKS; always on OCP | Include MaaS with AI Gateway |
| `ENABLE_BATCH_GATEWAY` | `false` on xKS; always on OCP | Include Batch Gateway with AI Gateway |
| `AKS_MONITORING_TYPE` | `self-hosted` | `managed` for Azure Managed Prometheus, `self-hosted` for kube-prometheus-stack |
| `BATCH_GATEWAY_NAMESPACE` | `batch-gateway` | Namespace where batch-gateway is deployed |
| `RHAI_HELM_CHART_NS` | `rhai-gitops` | Ensure this match the namespace where Helm Chart is installed |
| `RHAI_HELM_RELEASE_NAME` | `rhaii` | The Helm release name used during installation |


**Example: AKS with Azure Managed Prometheus**

Set `AKS_MONITORING_TYPE=managed` in the must-gather Job to collect Azure Managed Prometheus data:

```bash
kubectl apply -f - <<EOF
apiVersion: batch/v1
kind: Job
metadata:
  name: must-gather-job
  namespace: ${NAMESPACE}
spec:
  template:
    spec:
      serviceAccountName: must-gather-sa
      imagePullSecrets:
      - name: redhat-pull-secret
      containers:
      - name: gather
        image: registry.redhat.io/rhoai/odh-must-gather-rhel9:v3.6.0
        command: ["/bin/bash", "-c", "cd /tmp && gather && sleep 600"]
        env:
        - name: AKS_MONITORING_TYPE
          value: "managed"
      restartPolicy: Never
EOF
```

## Developer Guide

To build custom image quay.io/myname/must-gather:1.2.3, can set GATHER_IMG and/or GATHER_IMG_VERSION
by default GATHER_IMG is set to 'quay.io/$USER_NAME/must-gather' and GATHER_IMG_VERSION is 'dev'

```
export GATHER_IMG=quay.io/myname/must-gather
export GATHER_IMG_VERSION=1.2.3
make build-and-push-must-gather

```

To collect data for custom repositories, set the following variables inside must-gather:

```
export OPERATOR_NAMESPACE=<name-for-operator-namespace>
export NOTEBOOKS_NAMESPACE=<name-for-notebooks-namespace>
export MONITORING_NAMESPACE=<name-for-monitoring-namespace>
export APPLICATIONS_NAMESPACE=<name-for-applications-namespace>
export MODEL_REGISTRIES_NAMESPACE=<name-for-model-registries-namespace>
export MAAS_NAMESPACE=<name-for-maas-namespace>
export RHAI_HELM_CHART_NS=<name-for-rhai-helm-chart-namespace>

```
