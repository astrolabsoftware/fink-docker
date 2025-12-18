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
message_help="""
Start Apache Kafka and Apache HBase services\n\n
Usage:\n
    ./start_services.sh [--hbase-version] [--kafka-version] [-h] \n\n

Specify the versions with --<kafka, hbase>-version.\n
Use -h to display this help.
"""

# Show help if no arguments is given
if [[ $1 == "" ]]; then
  echo -e $message_help
  exit 1
fi

# Grab the command line arguments
while [ "$#" -gt 0 ]; do
  case "$1" in
    -h)
        echo -e $message_help
        exit
        ;;
    --kafka-version)
        if [[ $2 == "" ]]; then
          echo "$1 requires an argument" >&2
          exit 1
        fi
        KAFKA_VERSION="$2"
        shift 2
        ;;
    --hbase-version)
        if [[ $2 == "" ]]; then
          echo "$1 requires an argument" >&2
          exit 1
        fi
        HBASE_VERSION="$2"
        shift 2
        ;;
  esac
done

if [[ $KAFKA_VERSION == "" ]]; then
  echo "You need to specify the Kafka version with the option --version."
  exit
fi

if [[ $HBASE_VERSION == "" ]]; then
  echo "You need to specify the HBase version with the option --version."
  exit
fi

export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))

hbase-${HBASE_VERSION}/bin/start-hbase.sh

# Zookeeper already started with HBase standalone
kafka_2.12-${KAFKA_VERSION}/bin/kafka-server-start.sh kafka_2.12-${KAFKA_VERSION}/config/server.properties &

exec "$@"
