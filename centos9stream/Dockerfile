# Copyright 2022 AstroLab Software
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
FROM quay.io/centos/centos:stream9
LABEL maintainer="peloton@lal.in2p3.fr"

ENV PYTHON_VERSION=py39_4.11.0
ENV SPARK_VERSION=3.1.3
ENV HBASE_VERSION=2.4.10
ENV KAFKA_VERSION=2.8.1
ENV HADOOP_VERSION=hadoop3.2
ENV USRLIBS /home/libs

ENV SPARK_HOME=$USRLIBS/spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}
ENV KAFKA_HOME=$USRLIBS/kafka
ENV SPARKLIB=${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.9-src.zip
ENV PATH=${USRLIBS}/miniconda/bin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:/usr/local/bin:${PATH}
ENV PYTHONPATH=${SPARKLIB}:${PYTHONPATH}

WORKDIR $USRLIBS
COPY . .

# Install system build dependencies
RUN dnf -y update \
&& dnf -y install lsof which git wget java-11-openjdk \
&& dnf -y groupinstall "Development Tools" \
&& dnf -y clean all \
&& rm -rf /var/cache/dnf \
&& echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(type -P java))))" > /etc/profile.d/javahome.sh

# install python
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${PYTHON_VERSION}-Linux-x86_64.sh -O ~/miniconda.sh \
&& bash ~/miniconda.sh -b -p ${USRLIBS}/miniconda

# Install Apache Kafka, HBase and Spark. Install Python deps.
RUN source scripts/install_kafka.sh --version ${KAFKA_VERSION} \
&& source scripts/install_hbase.sh --version ${HBASE_VERSION} \
&& source scripts/install_spark.sh --spark-version ${SPARK_VERSION} --hadoop-version ${HADOOP_VERSION} \
&& cd $USRLIBS/centos7 && pip install --no-cache-dir --upgrade pip setuptools wheel && source ./install_python_deps.sh

ENTRYPOINT source scripts/start_services.sh --kafka-version ${KAFKA_VERSION} --hbase-version ${HBASE_VERSION} && /bin/bash
