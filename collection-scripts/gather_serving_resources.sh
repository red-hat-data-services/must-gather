# Shared resource list for KServe collection on OpenShift and xKS.
# shellcheck disable=SC2034
resources=("inferenceservices" "inferencegraphs" "trainedmodels" "servingruntimes" "clusterstoragecontainers" "predictors" "localmodelnodegroups")
# Dependent resources authorino
resources+=("authconfigs" "authorinos" "authpolicies.kuadrant.io")
# Dependent resources NIM
resources+=("accounts.nim.opendatahub.io")
# KServe LLM and worker resources.
resources+=(
  "llminferenceserviceconfigs.serving.kserve.io"
  "llminferenceservices.serving.kserve.io"
  "inferencepools.inference.networking.k8s.io"
)

# Module operator
resources+=("kserves.components.platform.opendatahub.io")
