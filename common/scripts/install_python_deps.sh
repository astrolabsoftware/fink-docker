#!/bin/bash
# Copyright 2019-2025 AstroLab Software
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

set -e

message_help="""
Install Python dependencies for fink-broker through pip\n\n
Usage:\n
    \t./install_python_deps.sh [SURVEY]\n\n
SURVEY: rubin or ztf (auto-detected from current directory if not specified)
"""

# Auto-detect survey from current directory or use parameter
if [[ $# -eq 0 ]]; then
    SURVEY=$(basename "$PWD")
else
    SURVEY=$1
fi

echo "Installing Python dependencies for survey: $SURVEY"

# Validate survey
if [[ ! "$SURVEY" =~ ^(rubin|ztf)$ ]]; then
    echo "Error: Invalid survey '$SURVEY'. Must be 'rubin' or 'ztf'"
    echo -e "$message_help"
    exit 1
fi

# Install dependencies
echo "Installing base requirements..."
pip install --no-cache-dir -r requirements.txt -r requirements-science.txt -r requirements-test.txt

echo "Installing science dependencies without deps..."
pip install -r requirements-science-no-deps.txt --no-deps

# ZTF-specific: dustmaps initialization
if [[ "$SURVEY" == "ztf" ]]; then
    echo "Initializing dustmaps for ZTF..."
    python -c "from dustmaps.config import config;import dustmaps.sfd;dustmaps.sfd.fetch()"
fi

echo "Python dependencies installation completed for $SURVEY"