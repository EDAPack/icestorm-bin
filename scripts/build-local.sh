#!/bin/bash
# Build locally using the same manylinux Docker image as CI.
# Usage: ./scripts/build-local.sh [image]
#   image - manylinux image name (default: manylinux_2_34_x86_64)

set -e

IMAGE="${1:-manylinux_2_34_x86_64}"

echo "Image: ${IMAGE}"

docker run --rm \
    --volume "$(pwd):/io" \
    --env image="${IMAGE}" \
    --workdir /io \
    "quay.io/pypa/${IMAGE}" \
    /io/scripts/build.sh
