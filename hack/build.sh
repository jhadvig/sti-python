#!/bin/bash -e
# $1 - Specifies distribution - RHEL7/CentOS7
# $2 - Specifies Python version - 3.3
# TEST_MODE - If set, build a candidate image and test it
OS=$1
VERSION=$2

# Array of all versions of Python
declare -a VERSIONS=(3.3)

# TODO: Remove this hack once Docker 1.5 is in use,
# which supports building of named Dockerfiles.
function docker_build {
  TAG=$1
  DOCKERFILE=$2

  if [ -n "$DOCKERFILE" -a "$DOCKERFILE" != "Dockerfile" ]; then
    # Swap Dockerfiles and setup a trap restoring them
    mv Dockerfile Dockerfile.centos7
    mv "${DOCKERFILE}" Dockerfile
    trap "mv Dockerfile ${DOCKERFILE} && mv Dockerfile.centos7 Dockerfile" ERR RETURN
  fi

  docker build -t ${TAG} . && trap - ERR
}

if [ -z ${VERSION} ]; then
  # Build all versions
  dirs=${VERSIONS}
else
  # Build only specified version of Python
  dirs=${VERSION}
fi

for dir in ${dirs[@]}; do
  IMAGE_NAME=openshift/python-${dir//./}-${OS}
  if [ -v TEST_MODE ]; then
    IMAGE_NAME="${IMAGE_NAME}-candidate"
  fi
  echo ">>>> Building ${IMAGE_NAME}"

  pushd ${dir} > /dev/null

  if [ "$OS" == "rhel7" ]; then
    docker_build ${IMAGE_NAME} Dockerfile.rhel7
  else
    docker_build ${IMAGE_NAME}
  fi

  if [ -v TEST_MODE ]; then
    IMAGE_NAME=${IMAGE_NAME} test/run
  fi

  popd > /dev/null
done
