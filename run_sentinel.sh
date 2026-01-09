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

# Run Fink sentinel Docker containers

set -euo pipefail

usage() {
  cat << EOD

Usage: $(basename "$0") [options]

  Available options:
    -h                  this message
    -t SURVEY           survey to run: rubin, ztf
    --tag TAG          docker tag name (default: latest)
    --cmd COMMAND      command to run in container (default: bash)
    --mount PATH       mount local directory into container at /workspace
    --port PORT        expose container port to host (format: host:container)

Run Fink sentinel Docker containers:
  - rubin: Run sentinel development container for Rubin survey
  - ztf: Run sentinel development container for ZTF survey

Examples:
  $(basename "$0") -t ztf                                       # Run ZTF container with latest tag
  $(basename "$0") -t rubin --tag v2.52.0-83-g8db26f3         # Run Rubin container with specific tag
  $(basename "$0") -t ztf --tag latest --cmd "python --version" # Run specific command
  $(basename "$0") -t ztf --mount ./code                       # Mount local directory
  $(basename "$0") -t ztf --port 8080:8080                    # Expose port

EOD
}

# Default values
SURVEY=""
TAG="latest"
CMD="bash"
MOUNT_PATH=""
PORT_MAPPING=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -t|--survey)
            SURVEY="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --cmd)
            CMD="$2"
            shift 2
            ;;
        --mount)
            MOUNT_PATH="$2"
            shift 2
            ;;
        --port)
            PORT_MAPPING="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ -z "$SURVEY" ]]; then
    echo "Error: Survey (-t) is required"
    usage
    exit 1
fi

if [[ ! "$SURVEY" =~ ^(rubin|ztf)$ ]]; then
    echo "Error: Invalid survey '$SURVEY'. Must be: rubin or ztf"
    exit 1
fi

# Build image name from survey and tag
IMAGE_NAME="gitlab-registry.in2p3.fr/astrolabsoftware/fink/fink-deps-sentinel-${SURVEY}:${TAG}"

# Prepare docker run arguments
DOCKER_ARGS=("-it" "--rm")

# Add port mapping if specified
if [[ -n "$PORT_MAPPING" ]]; then
    DOCKER_ARGS+=("-p" "$PORT_MAPPING")
fi

# Add mount if specified
if [[ -n "$MOUNT_PATH" ]]; then
    if [[ ! -d "$MOUNT_PATH" ]]; then
        echo "Error: Mount path '$MOUNT_PATH' is not a directory"
        exit 1
    fi

    # Convert to absolute path
    MOUNT_PATH=$(realpath "$MOUNT_PATH")
    DOCKER_ARGS+=("-v" "$MOUNT_PATH:/workspace")
    echo "Mounting $MOUNT_PATH to /workspace in container"
fi

# Add image name
DOCKER_ARGS+=("$IMAGE_NAME")

# Add command
if [[ "$CMD" == "bash" ]]; then
    DOCKER_ARGS+=("bash")
else
    # For non-interactive commands, don't use -it
    DOCKER_ARGS[0]="-i"
    DOCKER_ARGS+=("sh" "-c" "$CMD")
fi

echo "Running $SURVEY sentinel container: $IMAGE_NAME"
if [[ -n "$MOUNT_PATH" ]]; then
    echo "Working directory mounted at /workspace"
fi

# Run the container
docker run "${DOCKER_ARGS[@]}"