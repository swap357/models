#!/bin/bash
set -e

# The working dir in the container is /host
source "./shared_vars.sh"

PYTHON_VERSION="3.10"

#install prereqs
apt update
apt install -y python${PYTHON_VERSION} pip git

#install the collated requirements
pip install -r "${HOST_PATH}/${COLLATED_REQUIREMENTS_FILENAME}"
pip freeze > "${HOST_PATH}/${FROZEN_COLLATED_REQUIREMENTS_FILENAME}"
