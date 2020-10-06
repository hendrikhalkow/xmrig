#!/usr/bin/env bash

set -ex

# delete build containers on exit
trap cleanup INT EXIT
cleanup() {
  test -n "${ubi_ctr}" && buildah rm "${ubi_ctr}" || true
  test -n "${xmrig_ctr}" && buildah rm "${xmrig_ctr}" || true
}

pushd xmrig >/dev/null

theirs="48edfHu7V9Z84YzzMa6fUueoELZ9ZRXq9VetWzYGzKt52XU5xvqgzYnDK9URnRoJMk1j8nLwEVsaSWJ4fhdUyZijBGUicoD"
mine="473h97GMquMBdkGiman3u6fDdcLFD8PWPhoZ8y5vTe3Vheuua44vHTGdP3na4r3b3bZmaR3SsWF6n1P89echg7RGAqvMiaF"

find . \( -type d -name .git -prune \) -o -type f -print0 | xargs -0 sed -i "s/${theirs}/${mine}/g"
sed -i "s/kDefaultDonateLevel = 1/kDefaultDonateLevel = 0/g" src/donate.h
sed -i "s/kMinimumDonateLevel = 1/kMinimumDonateLevel = 0/g" src/donate.h

mkdir build
pushd scripts >/dev/null
./build_deps.sh
popd >/dev/null

pushd build >/dev/null
cmake .. -DXMRIG_DEPS=scripts/deps
make -j$(nproc)
popd >/dev/null

popd >/dev/null

semver="${1}"

# Set *_version variables from Dockerfile
eval $(cat Dockerfile | grep ^FROM | sed "s/^FROM \([^:]*\):\([0-9.-]*\) as \(.*\)/\3_version=\"\2\"; \3_image=\"\1:\2\"/")
xmrig_ctr="$( buildah from --pull --quiet "${ubi_image}" )"
xmrig_mnt="$( buildah mount "${xmrig_ctr}" )"

ldd ./xmrig/build/xmrig
cp ./xmrig/build/xmrig "${xmrig_mnt}/usr/local/bin"
ls -la "${xmrig_mnt}/usr/local/bin"

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
  --entrypoint '[ "/usr/local/bin/xmrig" ]' \
  --cmd "--help" \
  --user 1001 \
  --workingdir '/var' \
  "${xmrig_ctr}"

buildah commit --quiet --rm "${xmrig_ctr}" xmrig
xmrig_ctr=
