#!/usr/bin/env bash
#
# Copyright (c) 2023 Intel Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

MODEL_DIR=${MODEL_DIR-$PWD}

if [ ! -e "${MODEL_DIR}/models/graph_classification/pytorch/training/training.py" ]; then
  echo "Could not find the script of training.py. Please set environment variable '\${MODEL_DIR}'."
  echo "From which the training.py exist at the: \${MODEL_DIR}/models/graph_classification/pytorch/training/training.py"
  exit 1
fi


dir=$(pwd)
cd ${MODEL_DIR}/models/graph_classification/pytorch/training/
pip install -r requirements.txt -f https://data.pyg.org/whl/torch-2.0.0+cpu.html
