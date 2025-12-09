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

## Usage

To collect all for RHOAI release 3.0

```
oc adm must-gather --image=quay.io/modh/must-gather:rhoai-3.0
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

for example to 'kserve':

```
oc adm must-gather --image=quay.io/modh/must-gather:rhoai-2.17 -- "export COMPONENT=kserve; /usr/bin/gather"
```

To collect logs after a specific date (RFC3339). This feature only support oc 4.16+
Defaults to all logs.
If this value is in the future, no logs will be returned.
If this value precedes the time a pod was started, only logs since the pod start will be returned.
Only one of MUST_GATHER_SINCE_TIME / MUST_GATHER_SINCE may be used

```cmd
oc adm must-gather --image=quay.io/modh/must-gather:rhoai-3.0 --since-time=2024-05-02T14:01:23Z
```

To collect logs newer than a relative duration like 5s, 2m, or 3h. This feature only support oc 4.16+
Defaults to all logs.
Only one of MUST_GATHER_SINCE_TIME / MUST_GATHER_SINCE may be used

```cmd
oc adm must-gather --image=quay.io/modh/must-gather:rhoai-3.0 --since=3h
```

If you have enabled customized namespaces for installation, below env. variable need to be configured when running "oc adm must-gather", example:
```
oc adm must-gather --image=quay.io/modh/must-gather:rhoai-3.0 -- "export OPERATOR_NAMESPACE=<your-operator-namespace>;export APPLICATIONS_NAMESPACE=<your-application-namespace>; /usr/bin/gather"
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
export MASS_NAMESPACE=<name-for-maas-namespace>

```
