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
Install Python dependencies for fink-broker through pip

Usage:
    ./install_python_deps.sh [OPTIONS]

OPTIONS:
    -s, --survey SURVEY     Survey: rubin or ztf (auto-detected from current directory if not specified)
    --science              Install all dependencies including science packages (default)
    --noscience            Install only base and test dependencies
    -h, --help             Show this help message

Examples:
    ./install_python_deps.sh --survey ztf --science
    ./install_python_deps.sh -s rubin --noscience
"""

# Default values
SURVEY=$(basename "$PWD")
MODE="science"

# Parse command line options
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--survey)
            SURVEY="$2"
            shift 2
            ;;
        --science)
            MODE="science"
            shift
            ;;
        --noscience)
            MODE="noscience"
            shift
            ;;
        -h|--help)
            echo -e "$message_help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo -e "$message_help"
            exit 1
            ;;
    esac
done

echo "Installing Python dependencies for survey: $SURVEY, mode: $MODE"

# Validate survey
if [[ ! "$SURVEY" =~ ^(rubin|ztf)$ ]]; then
    echo "Error: Invalid survey '$SURVEY'. Must be 'rubin' or 'ztf'"
    echo -e "$message_help"
    exit 1
fi

# Install base dependencies (always installed)
echo "Installing base requirements..."
pip install --no-cache-dir --upgrade pip setuptools wheel
pip install --no-cache-dir -r requirements.txt

# Install test dependencies for noscience mode
if [[ "$MODE" == "noscience" ]]; then
    echo "Installing test requirements..."
    pip install -r requirements-test.txt
fi

# Install science dependencies for science mode
if [[ "$MODE" == "science" ]]; then
    echo "Installing test requirements..."
    pip install -r requirements-test.txt

    echo "Installing science requirements..."
    pip install -r requirements-science.txt --use-pep517

    echo "Installing science dependencies without deps..."
    pip install -r requirements-science-no-deps.txt --no-deps

    # ZTF-specific: dustmaps initialization
    if [[ "$SURVEY" == "ztf" ]]; then
        echo "Initializing dustmaps for ZTF..."
        python -c "from dustmaps.config import config;import dustmaps.sfd;dustmaps.sfd.fetch()"
    fi
fi

echo "Python dependencies installation completed for $SURVEY (mode: $MODE)"