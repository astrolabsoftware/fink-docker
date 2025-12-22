#!/bin/bash
# Copyright 2022-2024 AstroLab Software
# Author: Julien Peloton
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Setup environment variables for Spark, Kafka, and Python tools
# Makes spark-submit, kafka-topics, and other binaries available in all shells

if [[ -z "$SURVEY" ]]; then
  echo "ERROR: SURVEY environment variable is not set"
  exit 1
fi

VERSIONS_FILE="${FINK_BROKER_ROOT}/sentinel/versions.${SURVEY}.sh"
if [[ ! -f "$VERSIONS_FILE" ]]; then
  echo "ERROR: Versions file not found: $VERSIONS_FILE"
  exit 1
fi

# Load versions
source "$VERSIONS_FILE"

# Set environment variables
export SPARK_HOME="$FINK_BROKER_ROOT/spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}"
export KAFKA_HOME="$FINK_BROKER_ROOT/kafka"
export SPARKLIB="${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.9.7-src.zip"
export PATH="$FINK_BROKER_ROOT/miniconda/bin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:/usr/local/bin:${PATH}"
export BINPATH="${PATH}"
export PYTHONPATH="${SPARKLIB}:${PYTHONPATH}"