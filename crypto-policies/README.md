# DEFAULT:PQ configuration

`generated/` contains the output of `update-crypto-policies --no-reload --set
DEFAULT:PQ`, generated using the final base image pinned in `Dockerfile.konflux`
and `crypto-policies-scripts-20260224-1.gitea0f072.el9_8.noarch`.

The base image includes the policy definitions but omits the update tool.
Checking in the generated configuration lets the Konflux build remain hermetic
without downloading RPMs. The configuration is architecture independent.
The Dockerfile checks the installed policy package version to prevent silently
using stale configuration after a base image update.

To regenerate, run from the repository root with access to the Red Hat registry
and UBI package repositories:

```bash
set -e
base_image=$(awk ' $1 == "FROM" { image = $2 } END { print image }' Dockerfile.konflux)
container=$(podman create --user 0 --entrypoint /bin/sh "$base_image" -ec '
    version=$(rpm -q --qf "%{VERSION}-%{RELEASE}" crypto-policies)
    dnf install -y --setopt=install_weak_deps=False "crypto-policies-scripts-$version"
    update-crypto-policies --no-reload --set DEFAULT:PQ
    update-crypto-policies --check
    rpm -q crypto-policies crypto-policies-scripts
    mkdir -p /tmp/crypto-policies-generated
    cp -aL /etc/crypto-policies/. /tmp/crypto-policies-generated/
')
podman start --attach "$container"
test "$(podman inspect --format '{{.State.ExitCode}}' "$container")" = 0
podman cp "$container:/tmp/crypto-policies-generated/." crypto-policies/generated/
podman rm "$container"
```

Review the generated diff and update the package version check in
`Dockerfile.konflux` and the provenance above if the RPM version changed.
Build with `podman build --network=none -f Dockerfile.konflux .` to verify that
no package downloads are required. Retrieve `bin/helm` with Git LFS before
building an image intended for use.
