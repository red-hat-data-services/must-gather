# must-gather for Red Hat OpenShift AI

The must-gather script allows a cluster admin to collect information about various key resources and namespaces
for Red Hat OpenShift Data Science.

## Data Collected

The must-gather script currently collects data from following default namespaces

- redhat-ods-operator
- rhods-notebooks
- redhat-ods-applications
- redhat-ods-monitoring

and datasciencecluster and dscinitialization instances from cluster

This script also collects data from all the namespaces that has

- `DataSciencePipelinesApplication` instances for Data Science Pipeline component
- `appwrappers` `quotasubtrees` `gschedulingspecs` for Codeflare component
- `rayclusters` `rayjobs` `rayservices` for KubeRay component
- `clusterqueues` `localqueues` `multikueueclusters` `multikueueconfigs` `provisioningrequestconfigs` `resourceflavors` `workloads` `workloadpriorityclasses` for Kueue component
- `notebooks` for Workbench component
- `inferenceservice` `inferencegraphs` for Kserve and ModelMesh component

## Usage

To collect all

```
oc adm must-gather --image=quay.io/modh/must-gather:stable
```

To collect for only one component  use env variable COMPONENT.
for example to 'kserve':

```
export COMPONENT=kserve
oc adm must-gather --image=quay.io/modh/must-gather:stable
```

To collect for specific date(RFC3339):

```
export MUST_GATHER_SINCE_TIME=2024-03-28_16:01:23Z
```

To collect newer than a relative duration like 5s, 2m, or 3h

```
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
