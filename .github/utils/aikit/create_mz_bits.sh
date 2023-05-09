#!/bin/bash
set -e

MZ_VERSION=$1
AIKIT_VERSION=$2
WORKSPACE=$3
BRANCH_NAME=$4

# Create the drop directory
DROP_NAME="l_model-zoo-${MZ_VERSION}-${AIKIT_VERSION}-drop"
if [ -d "${WORKSPACE}/${DROP_NAME}" ]; then
    rm -rf ${WORKSPACE}/${DROP_NAME}
fi

mkdir -p ${WORKSPACE}/${DROP_NAME}
cp -r l_model-zoo-drop-sample/* ${WORKSPACE}/${DROP_NAME}

# Add the models source code based on the input branch
cd ${WORKSPACE}/${DROP_NAME}
git clone https://github.com/intel-innersource/frameworks.ai.models.intel-models.git models
cd models
git checkout ${BRANCH_NAME}
rm -rf .git .gitignore .github

# Update model zoo version environment variable
cd ${WORKSPACE}/${DROP_NAME}/env
echo "$(head -n -1 vars.sh)" > vars.sh
echo "export MODEL_ZOO_VERSION=${MZ_VERSION}" >> vars.sh

# Create the bom file
if [ ! -d "${WORKSPACE}/${DROP_NAME}/boms" ]; then
    mkdir -p ${WORKSPACE}/${DROP_NAME}/boms
else
    # Remove the old bom file before creating a new one
    rm -rf ${WORKSPACE}/${DROP_NAME}/boms/*
fi

cd ${WORKSPACE}
python create_bom_file.py --drop_delivery_dir ${WORKSPACE}/${DROP_NAME}

echo ""
echo "Successfully created Model Zoo bits in ${WORKSPACE}/${DROP_NAME}"
echo ""
