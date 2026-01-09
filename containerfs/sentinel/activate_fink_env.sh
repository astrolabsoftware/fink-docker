#!/bin/bash

BRANCH="issue/770/duplicates"
git clone -b $BRANCH https://github.com/astrolabsoftware/fink-broker.git
cd fink-broker
export FINK_HOME=$PWD

git clone -b $BRANCH https://github.com/astrolabsoftware/fink-alert-simulator.git
export FINK_ALERT_SIMULATOR=${FINK_HOME}/fink-alert-simulator/rootfs/fink

git clone https://github.com/astrolabsoftware/fink-alert-schemas.git
export FINK_SCHEMA=${FINK_HOME}/fink-alert-schemas

export PYTHONPATH=${FINK_HOME}:${FINK_ALERT_SIMULATOR}:${PYTHONPATH}
export PATH=$PATH:${FINK_HOME}/bin:${FINK_ALERT_SIMULATOR}/bin
