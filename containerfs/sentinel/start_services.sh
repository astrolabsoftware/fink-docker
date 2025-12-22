#!/bin/bash
# Copyright 2022 AstroLab Software
# Author: Abhishek Chauhan, Julien Peloton
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

# Auto-load versions based on SURVEY environment variable
if [[ -z "$SURVEY" ]]; then
  echo "ERROR: SURVEY environment variable is not set"
  exit 1
fi

VERSIONS_FILE="${FINK_BROKER_ROOT}/sentinel/versions.${SURVEY}.sh"
if [[ ! -f "$VERSIONS_FILE" ]]; then
  echo "ERROR: Versions file not found: $VERSIONS_FILE"
  exit 1
fi

echo "Loading versions for survey: $SURVEY"
source "$VERSIONS_FILE"

if [[ -z "$KAFKA_VERSION" || -z "$HBASE_VERSION" ]]; then
  echo "ERROR: KAFKA_VERSION or HBASE_VERSION not loaded from $VERSIONS_FILE"
  exit 1
fi

echo "Starting services with Kafka $KAFKA_VERSION and HBase $HBASE_VERSION"
echo "Using JAVA_HOME: $JAVA_HOME"

${FINK_BROKER_ROOT}/hbase-${HBASE_VERSION}/bin/start-hbase.sh

# Wait for ZooKeeper to be ready before starting Kafka
echo "Waiting for ZooKeeper to be ready..."
for i in {1..30}; do
  # Try to connect to ZooKeeper using telnet or timeout-based connection test
  if timeout 2 bash -c "</dev/tcp/localhost/2181" 2>/dev/null; then
    echo "ZooKeeper is ready"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "ERROR: ZooKeeper failed to start within 30 seconds"
    exit 1
  fi
  echo "ZooKeeper not ready yet, waiting... ($i/30)"
  sleep 1
done

# Start Kafka now that ZooKeeper is ready
${FINK_BROKER_ROOT}/kafka_2.12-${KAFKA_VERSION}/bin/kafka-server-start.sh ${FINK_BROKER_ROOT}/kafka_2.12-${KAFKA_VERSION}/config/server.properties &

# Wait for Kafka to be ready
echo "Waiting for Kafka to be ready..."
for i in {1..30}; do
  # Check if Kafka is ready by trying to list topics
  if ${FINK_BROKER_ROOT}/kafka_2.12-${KAFKA_VERSION}/bin/kafka-topics.sh --bootstrap-server localhost:9092 --list >/dev/null 2>&1; then
    echo "Kafka is ready"
    break
  fi
  if [ $i -eq 30 ]; then
    echo "ERROR: Kafka failed to start within 30 seconds"
    exit 1
  fi
  echo "Kafka not ready yet, waiting... ($i/30)"
  sleep 1
done

echo "All services started successfully"
