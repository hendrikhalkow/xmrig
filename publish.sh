#!/bin/sh -ex

buildah push \
  --format v2s2 \
  --creds "${OCI_REGISTRY_USERNAME}:${OCI_REGISTRY_TOKEN}" \
  xmrig "docker://quay.io/hendrikhalkow/xmrig:${1}"
