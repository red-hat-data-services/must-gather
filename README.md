# must-gather for Red Hat OpenShift Data Science

The must-gather script allows a cluster admin to collect information about various key resources and namespaces
for Red Hat OpenShift Data Science.

## Data Collected

The must-gather script currently collects data from following namespaces

- redhat-ods-operator
- redhat-ods-applications
- redhat-ods-monitoring

## Usage

```
oc adm must-gather --image=quay.io/modh/must-gather:v1.0.0
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
export MONITORING_NS= <name-for-monitoring-namespace>
export APPLICATIONS_NS= <name-for-applications-namespace>

```
