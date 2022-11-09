#!/bin/bash
IMAGE=$1
set -x

docker pull $IMAGE
IMAGE_VERSION=$(docker inspect   --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' $IMAGE)
SHORT_IMAGE_VERSION=${IMAGE_VERSION%%-snapshot*}
BASE_IMAGE_VERSION=${IMAGE_VERSION%%-*}

sed -i "s/^appVersion:.*$/appVersion: ${IMAGE_VERSION}/" charts/admission-controller/Chart.yaml
sed -i "s/^version:.*$/version: $SHORT_IMAGE_VERSION/" charts/admission-controller/Chart.yaml

REPO_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' $IMAGE)
REPO_DIGEST_TAG=${REPO_DIGEST##*@}
sed -i "s|sha256:.*$|${REPO_DIGEST_TAG}|" charts/admission-controller/Chart.yaml
sed -i "s|version:.*$|version: v${IMAGE_VERSION}-admission|" charts/admission-controller/values.yaml
