#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Unified build script for Fink Docker images

set -euo pipefail

DIR=$(cd "$(dirname "$0")"; pwd -P)

usage() {
  cat << EOD

Usage: $(basename "$0") [options]

  Available options:
    -h                  this message
    -t TARGET           target to build: k8s, rubin, ztf
    -s SUFFIX           image suffix for k8s builds: noscience, science (default: science)
    -i SURVEY           survey for k8s builds: ztf, rubin (default: ztf)
    --tag TAG          docker tag name (required for rubin/ztf builds)
    --verbose           verbose build output

Build Fink Docker images:
  - k8s: Build Kubernetes image using Dockerfile.k8s
  - rubin: Build sentinel development image for Rubin survey
  - ztf: Build sentinel development image for ZTF survey

Examples:
  $(basename "$0") -t k8s -s noscience -i ztf     # K8s noscience image for ZTF
  $(basename "$0") -t k8s -s science -i rubin     # K8s science image for Rubin
  $(basename "$0") -t rubin --tag myrubin:latest  # Sentinel Rubin image
  $(basename "$0") -t ztf --tag myztf:latest      # Sentinel ZTF image

EOD
}

# Default values
TARGET=""
SUFFIX="science"
SURVEY="ztf"
TAG=""
VERBOSE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -s|--suffix)
            SUFFIX="$2"
            shift 2
            ;;
        -i|--survey)
            SURVEY="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate target
if [[ -z "$TARGET" ]]; then
    echo "Error: Target (-t) is required"
    usage
    exit 1
fi

if [[ ! "$TARGET" =~ ^(k8s|rubin|ztf)$ ]]; then
    echo "Error: Invalid target '$TARGET'. Must be: k8s, rubin, or ztf"
    exit 1
fi

# Validate survey for k8s builds
if [[ "$TARGET" == "k8s" && ! "$SURVEY" =~ ^(ztf|rubin)$ ]]; then
    echo "Error: Invalid survey '$SURVEY' for k8s build. Must be: ztf or rubin"
    exit 1
fi

# Validate suffix for k8s builds
if [[ "$TARGET" == "k8s" && ! "$SUFFIX" =~ ^(science|noscience)$ ]]; then
    echo "Error: Invalid suffix '$SUFFIX' for k8s build. Must be: science or noscience"
    exit 1
fi

# Require tag for local builds
if [[ "$TARGET" =~ ^(rubin|ztf)$ && -z "$TAG" ]]; then
    echo "Error: Tag (--tag) is required for $TARGET builds"
    exit 1
fi

# Set verbose options
EXTRA_ARGS=""
if [[ "$VERBOSE" == true ]]; then
    EXTRA_ARGS="--progress=plain"
fi

# Build functions
build_k8s() {
    echo "Building K8s image for $SURVEY survey with $SUFFIX target"

    # This command avoid retrieving build dependencies if not needed
    $(ciux get image --check "$DIR" --suffix "$SUFFIX" --env)

    if [ "$CIUX_BUILD" = false ]; then
        echo "Build cancelled, image $CIUX_IMAGE_URL already exists and contains current source code"
        echo "Run following command to prepare integration tests:"
        echo "  ciux ignite --selector build,k8s \"$DIR\" --suffix \"$SUFFIX\""
        exit 0
    fi

    ciux ignite --selector build,k8s "$DIR" --suffix "$SUFFIX"
    . $DIR/.ciux.d/ciux_build.sh

    # Determine docker target
    if [[ "$SUFFIX" =~ ^noscience* ]]; then
        docker_target="noscience"
    else
        docker_target="full"
    fi

    # Build K8s image
    docker image build $EXTRA_ARGS \
        --tag "$CIUX_IMAGE_URL" \
        --build-arg spark_py_image="$ASTROLABSOFTWARE_FINK_SPARK_PY_IMAGE" \
        --build-arg input_survey="$SURVEY" \
        --file Dockerfile.k8s \
        --target "$docker_target" \
        "$DIR"

    echo "Build successful: $CIUX_IMAGE_URL"
    echo "Run following command to prepare integration tests:"
    echo "  ciux ignite --selector ci \"$DIR\" --suffix \"$SUFFIX\""
}

build_sentinel() {
    local survey="$1"
    echo "Building sentinel development image for $survey survey"

    if [[ ! -d "$survey" ]]; then
        echo "Error: Directory '$survey' not found"
        exit 1
    fi

    if [[ ! -f "$survey/Dockerfile" ]]; then
        echo "Error: Dockerfile not found in '$survey' directory"
        exit 1
    fi

    echo "Building $survey image with tag: $TAG"
    docker build $EXTRA_ARGS \
        -f "$survey/Dockerfile" \
        -t "$TAG" \
        .

    echo "Build successful: $TAG"
}

# Main execution
case "$TARGET" in
    k8s)
        build_k8s
        ;;
    rubin|ztf)
        build_sentinel "$TARGET"
        ;;
esac
