#!/usr/bin/env bash
#
# Copyright (c) 2021 Intel Corporation
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

if [ ! -e "${MODEL_DIR}/models/diffusion/pytorch/stable_diffusion/textual_inversion.py"  ]; then
    echo "Could not find the script of textual_inversion.py. Please set environment variable '\${MODEL_DIR}'."
    exit 1
fi

if [ -z "${OUTPUT_DIR}" ]; then
  echo "The required environment variable OUTPUT_DIR has not been set"
  exit 1
fi

# Create the output directory in case it doesn't already exist
mkdir -p ${OUTPUT_DIR}

ARGS=""
if [ "$1" == "bf16" ]; then
    ARGS="$ARGS --mixed_precision=bf16"
    echo "### running bf16 datatype"
elif [ "$1" == "fp16" ]; then
    ARGS="$ARGS --mixed_precision=fp16"
    echo "### running fp16 datatype"
elif [ "$1" == "fp32" ]; then
    echo "### running fp32 datatype"
else
    echo "The specified precision '$1' is unsupported."
    echo "Supported precisions are: fp32, fp16, bf16"
    exit 1
fi


CORES=`lscpu | grep Core | awk '{print $4}'`
SOCKETS=`lscpu | grep Socket | awk '{print $2}'`
TOTAL_CORES=`expr $CORES \* $SOCKETS`
NNODES=${NNODES:-1}
HOSTFILE=${HOSTFILE:-./hostfile}
NUM_RANKS=$(( NNODES * SOCKETS ))


CORES_PER_INSTANCE=$CORES

export DNNL_PRIMITIVE_CACHE_CAPACITY=1024
export KMP_BLOCKTIME=1
export KMP_AFFINITY=granularity=fine,compact,1,0

PRECISION=$1

export MODEL_NAME="runwayml/stable-diffusion-v1-5"
export DATA_DIR="./cat"

#oneCCL settings
export CCL_WORKER_COUNT=8
export CCL_LOG_LEVEL=info
export CCL_BF16=avx512bf
export CCL_ATL_TRANSPORT=ofi
export CCL_MNIC_COUNT=2
export CCL_MNIC=local
export CCL_MNIC_NAME=irdma1,irdma5
export CCL_ALLREDUCE=ring
export CCL_WORKER_COUNT=8

for (( i = $SOCKETS; i < 2*$SOCKETS; i++ )); do  # pin CCL workers to HT
  START_CORE=$(( i * CORES ))
  for (( j = 0; j < $CCL_WORKER_COUNT; j++)); do
   CCL_WORKER_AFFINITY="${CCL_WORKER_AFFINITY} $((START_CORE + j))"
  done
done

export CCL_WORKER_AFFINITY=`echo ${CCL_WORKER_AFFINITY} | tr " " ","`


#DDP settings
export TORCH_CPP_LOG_LEVEL=INFO
export TORCH_DISTRIBUTED_DEBUG=INFO
export MASTER_ADDR=`head -1 hostfile`

# Fabric settings
export FI_PROVIDER=psm3
export PSM3_IDENTIFY=1
export PSM3_ALLOW_ROUTERS=1
export PSM3_RDMA=1
export PSM3_PRINT_STATS=0
export PSM3_RV_MR_CACHE_SIZE=8192
export PSM3_KASSIST_MODE=none
#export PSM3_NIC='irdma*
export FI_PSM3_CONN_TIMEOUT=100

rm -rf ${OUTPUT_DIR}/stable_diffusion_dist_finetune_log_${PRECISION}*

oneccl_bindings_for_pytorch_path=$(python -c "import torch; import oneccl_bindings_for_pytorch; import os;  print(os.path.abspath(os.path.dirname(oneccl_bindings_for_pytorch.__file__)))")
source $oneccl_bindings_for_pytorch_path/env/setvars.sh

python -m intel_extension_for_pytorch.cpu.launch \
    --memory-allocator tcmalloc \
    --distributed \
    --nnodes ${NNODES} \
    --hostfile ${HOSTFILE} \
    --nprocs-per-node ${SOCKETS} \
    --ncores-per-instance ${CORES_PER_INSTANCE} \
    --logical-cores-for-ccl --ccl_worker_count 8 \
    ${MODEL_DIR}/models/diffusion/pytorch/stable_diffusion/textual_inversion.py \
    --pretrained_model_name_or_path=$MODEL_NAME \
    --train_data_dir=$DATA_DIR \
    --learnable_property="object" \
    --placeholder_token="\"<cat-toy>\"" --initializer_token="toy" \
    --resolution=512 \
    --train_batch_size=1 \
    --gradient_accumulation_steps=4 \
    --num_train_epochs=20 \
    --learning_rate=5.0e-04 --scale_lr \
    --lr_scheduler="constant" \
    --lr_warmup_steps=0 \
    --output_dir="textual_inversion_cat_${PRECISION}" \
    --ipex $ARGS 2>&1 | tee ${OUTPUT_DIR}/stable_diffusion_dist_finetune_log_${PRECISION}.log