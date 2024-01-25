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
# ============================================================================
#
# THIS IS A GENERATED DOCKERFILE.
#
# This file was assembled from multiple pieces, whose use is documented
# throughout. Please refer to the TensorFlow dockerfiles documentation
# for more information.

ARG TF_BASE_IMAGE="intel/intel-extension-for-tensorflow"
ARG TF_BASE_TAG="xpu"

FROM ${TF_BASE_IMAGE}:${TF_BASE_TAG}

WORKDIR /workspace/tf-flex-series-maskrcnn-inference/models

RUN apt-get update && \
    apt-get install -y --no-install-recommends parallel pciutils numactl
    
RUN apt-get update && \
    apt-get install -y --no-install-recommends --fix-missing \
    git build-essential libssl-dev libffi-dev python3.10-dev

RUN python -m pip install opencv-python-headless pycocotools 

COPY models_v2/tensorflow/maskrcnn/inference/gpu .

RUN pip install git+https://github.com/NVIDIA/dllogger.git

RUN git clone https://github.com/NVIDIA/DeepLearningExamples.git && \
    cd DeepLearningExamples && \
    git checkout 5be8a3cae21ee2d80e3935a4746827cb3367bcac && \
    mv /workspace/tf-flex-series-maskrcnn-inference/models/EnableInference.patch . && \
    git apply EnableInference.patch && \
    cd -

COPY LICENSE license/LICENSE
COPY third_party license/third_party
