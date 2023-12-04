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
ARG PYTHON_VERSION=py39_4.11.0
ARG SPARK_VERSION=3.4.1
ARG HBASE_VERSION=2.4.10
ARG KAFKA_VERSION=2.8.1
ARG HADOOP_VERSION=hadoop3

FROM quay.io/centos/centos:stream9 AS builder
LABEL maintainer="peloton@lal.in2p3.fr"

ARG PYTHON_VERSION
ENV PYTHON_VERSION=$PYTHON_VERSION

ARG SPARK_VERSION
ENV SPARK_VERSION=$SPARK_VERSION

ARG HBASE_VERSION
ENV HBASE_VERSION=$HBASE_VERSION

ARG KAFKA_VERSION
ENV KAFKA_VERSION=$KAFKA_VERSION

ARG HADOOP_VERSION
ENV HADOOP_VERSION=$HADOOP_VERSION

ENV USRLIBS /home/libs

ENV PATH=${USRLIBS}/miniconda/bin:/usr/local/bin:${PATH}

WORKDIR $USRLIBS
COPY . .

# Install system build dependencies
RUN dnf -y update \
&& dnf -y install lsof which git wget \
&& dnf -y groupinstall "Development Tools" \
&& dnf -y clean all \
&& rm -rf /var/cache \
&& echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(type -P java))))" > /etc/profile.d/javahome.sh

# install python
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-${PYTHON_VERSION}-Linux-x86_64.sh -O ~/miniconda.sh \
&& bash ~/miniconda.sh -b -p ${USRLIBS}/miniconda

# Install Apache Kafka, HBase and Spark. Install Python deps.
RUN source scripts/install_kafka.sh --version ${KAFKA_VERSION} \
&& source scripts/install_hbase.sh --version ${HBASE_VERSION} \
&& source scripts/install_spark.sh --spark-version ${SPARK_VERSION} --hadoop-version ${HADOOP_VERSION} \
&& cd $USRLIBS/centos9stream \
&& pip install --no-cache-dir --upgrade pip setuptools wheel \
&& source ./install_python_deps.sh \
&& cd $USRLIBS \
&& find miniconda \( -type d -a -name test -o -name tests \) -o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) -exec rm -rf '{}' \+

# Stage 2
FROM quay.io/centos/centos:stream9

ARG PYTHON_VERSION
ENV PYTHON_VERSION=$PYTHON_VERSION

ARG SPARK_VERSION
ENV SPARK_VERSION=$SPARK_VERSION

ARG HBASE_VERSION
ENV HBASE_VERSION=$HBASE_VERSION

ARG KAFKA_VERSION
ENV KAFKA_VERSION=$KAFKA_VERSION

ARG HADOOP_VERSION
ENV HADOOP_VERSION=$HADOOP_VERSION

ENV USRLIBS /home/libs

ENV SPARK_HOME=$USRLIBS/spark-${SPARK_VERSION}-bin-${HADOOP_VERSION}
ENV KAFKA_HOME=$USRLIBS/kafka
ENV SPARKLIB=${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.9.7-src.zip
ENV PATH=${USRLIBS}/miniconda/bin:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:/usr/local/bin:${PATH}
ENV BINPATH=$PATH
ENV PYTHONPATH=${SPARKLIB}:${PYTHONPATH}

WORKDIR $USRLIBS

COPY --from=builder $USRLIBS $USRLIBS

# Install Java and useful utilities
RUN dnf -y update \
&& dnf -y install which git wget java-11-openjdk \
&& dnf -y clean all \
&& rm -rf /var/cache \
&& echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f $(type -P java))))" > /etc/profile.d/javahome.sh

ENV JAVA_HOME="$(dirname $(dirname $(readlink -f $(type -P java))))"

ENTRYPOINT source scripts/start_services.sh --kafka-version ${KAFKA_VERSION} --hbase-version ${HBASE_VERSION} && /bin/bash
