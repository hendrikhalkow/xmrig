#!/usr/bin/env bash

set -ex

# delete build containers on exit
trap cleanup INT EXIT
cleanup() {
  test -n "${ubi_ctr}" && buildah rm "${ubi_ctr}" || true
  test -n "${xmrig_ctr}" && buildah rm "${xmrig_ctr}" || true
}

semver="${1}"

# Set *_version variables from Dockerfile
eval $(cat Dockerfile | grep ^FROM | sed "s/^FROM \([^:]*\):\([0-9.-]*\) as \(.*\)/\3_version=\"\2\"; \3_image=\"\1:\2\"/")

oci_prefix="org.opencontainers.image"
buildah config \
  --label "${oci_prefix}.authors=Hendrik M Halkow <hendrik@halkow.com>" \
  --label "${oci_prefix}.url=https://github.com/xmrig/xmrig" \
  --label "${oci_prefix}.source=https://github.com/hendrikhalkow/xmrig" \
  --label "${oci_prefix}.version=${semver}" \
  --label "${oci_prefix}.revision=$( git rev-parse HEAD )" \
  --label "${oci_prefix}.vendor=Hendrik M Halkow" \
  --label "${oci_prefix}.licenses=AGPL-3.0" \
  --label "${oci_prefix}.title=XMRig" \
  --label "${oci_prefix}.description=High performance, open source, cross platform RandomX, KawPow, CryptoNight and AstroBWT unified CPU/GPU miner" \
  --user 1001 \
  --workingdir '/var' \
  "${xmrig_ctr}"

buildah commit --quiet --rm "${xmrig_ctr}" base
xmrig_ctr=
