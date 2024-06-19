# must-gather for Red Hat OpenShift AI

The must-gather script allows a cluster admin to collect information about various key resources and namespaces
for Red Hat OpenShift AI.

## Data Collected

The must-gather script currently collects data from following default namespaces

- redhat-ods-operator
- rhods-notebooks
- redhat-ods-applications
- redhat-ods-monitoring

and datasciencecluster and dscinitialization instances from cluster

This script also collects data from all the namespaces that has

- `datasciencepipelinesapplications` `scheduledworkflow` `applications` `clusterworkflowtemplates` `cronworkflows` `viewers` `workfloweventbindings` `workflows` `workflowtaskresults` `workflowtemplates` `workflowtasksets` for Data Science Pipeline component
- `rayclusters` `rayjobs` `rayservices` for KubeRay component
- `clusterqueues` `localqueues` `multikueueclusters` `multikueueconfigs` `provisioningrequestconfigs` `resourceflavors` `workloads` `workloadpriorityclasses` for Kueue component
- `mpijobs` `mxjobs` `paddlejobs` `pytorchjob` `tfjob` `xgboostjob`  for Kubeflow Training Operator
- `inferenceservice` `inferencegraphs` `"trainedmodels` `servingruntimes` `clusterstoragecontainers` `predictors` for Kserve and ModelMesh component
- `notebooks` for Workbench component

## Usage

To collect all

```
oc adm must-gather --image=quay.io/modh/must-gather:stable
```

Dashboard has been included in this default behavior.

To collect for only one component use env variable COMPONENT.
Full list of supported components see table below:
| COMPONENT value    | Comments |
| -------- | ------- |
| dsp  | Data Science Pipeline    |
| kuberay |  KubeRay     |
| kueue    | Kueue    |
| kfto | Kubeflow Training Operator |
| kserve    | Kserve    |
| modelmesh  | Model Mesh   |
| workbench | Workbench    |

for example to 'kserve':

```
export COMPONENT=kserve
oc adm must-gather --image=quay.io/modh/must-gather:stable
```

To collect logs after a specific date (RFC3339).
Defaults to all logs.
If this value is in the future, no logs will be returned.
If this value precedes the time a pod was started, only logs since the pod start will be returned.
Only one of MUST_GATHER_SINCE_TIME / MUST_GATHER_SINCE may be used

```cmd
MUST_GATHER_SINCE_TIME=2024-05-02T14:01:23Z
```

To collect logs newer than a relative duration like 5s, 2m, or 3h.
Defaults to all logs.
Only one of MUST_GATHER_SINCE_TIME / MUST_GATHER_SINCE may be used

```cmd
export MUST_GATHER_SINCE=3h
```

## Developer Guide

To build custom image :

```
export GATHER_IMG= <image-name>
make build-and-push-must-gather

```

To collect data for custom repositories for Open Data Hub set the following variables:

```
export OPERATOR_NS= <name-for-operator-namespace>
export NOTEBOOKS_NS= <name-for-notebooks-namespace>
export MONITORING_NS= <name-for-monitoring-namespace>
export APPLICATIONS_NS= <name-for-applications-namespace>

```
