#!/bin/bash

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


ARGS=""

export DNNL_PRIMITIVE_CACHE_CAPACITY=1024
#export MALLOC_CONF="oversize_threshold:1,background_thread:true,metadata_thp:auto,dirty_decay_ms:9000000000,muzzy_decay_ms:9000000000"

path="ipex"
ARGS="$ARGS  --benchmark --num-warmup 10 --num-iter 50  --token-latency"
echo "### running with intel extension for pytorch"
if [ -z "${OUTPUT_DIR}" ]; then
  echo "The required environment variable OUTPUT_DIR has not been set, please create the output path and set it to OUTPUT_DIR"
  exit 1
fi
precision="fp32"
if [[ "$1" == "bf16" ]]
then
    precision="bf16"
    ARGS="$ARGS --dtype 'bf16' "
    echo "### running bf16 mode"
elif [[ "$1" == "fp32" ]]
then
    echo "### running fp32 mode"
elif [[ "$1" == "fp16" ]]
then
    precision=fp16
    ARGS="$ARGS --dtype 'fp16'"
    echo "### running fp16 mode"
elif [[ "$1" == "bf32" ]]
then
    precision="bf32"
    ARGS="$ARGS --dtype 'bf32'"
    echo "### running bf32 mode"
elif [[ "$1" == "int8-fp32" ]]
then
    precision="int8-fp32"
    ARGS="$ARGS --dtype 'int8' --quantized_model_path '${OUTPUT_DIR}/best_model.pt'"
    echo "### running int8-fp32 mode"
elif [[ "$1" == "int8-bf16" ]]
then
    precision="int8-bf16"
    ARGS="$ARGS --dtype 'int8' --int8_bf16_mixed --quantized_model_path '${OUTPUT_DIR}/best_model.pt'"
    echo "### running int8-bf16 mode"
else
    echo "The specified precision '$1' is unsupported."
    echo "Supported precisions are: fp32, bf32, bf16, fp16, int8-fp32, int8-bf16"
    exit 1
fi

if [ -z "${OUTPUT_TOKEN}" ]; then
  echo "The required environment variable OUTPUT_TOKEN has not been set, please set before running, e.g. export OUTPUT_TOKEN=32"
  exit 1
fi
if [ -z "${INPUT_TOKEN}" ]; then
  echo "The required environment variable INPUT_TOKEN has not been set, please set before running (choice in 32 64 128 512 1024 2016 ), e.g. export INPUT_TOKEN=1024"
  exit 1
fi

mode="jit"
ARGS="$ARGS --jit"
echo "### running with jit mode"


export OMP_NUM_THREADS=${CORE_PER_INSTANCE}
CORES=`lscpu | grep Core | awk '{print $4}'`
# ARGS="$ARGS --use-share-weight --ws-total-cores ${CORES} --ws-cores-per-instance ${OMP_NUM_THREADS}"
SOCKETS=`lscpu | grep Socket | awk '{print $2}'`
BATCH_SIZE=${BATCH_SIZE:-1}
FINETUNED_MODEL=${FINETUNED_MODEL:-"'meta-llama/Llama-2-7b-hf'"}

EVAL_SCRIPT=${EVAL_SCRIPT:-"../../../../../../models/language_modeling/pytorch/llama/inference/cpu/run_llm.py"}
WORK_SPACE=${WORK_SPACE:-${OUTPUT_DIR}}
rm -rf ${OUTPUT_DIR}/latency_log*
python -m intel_extension_for_pytorch.cpu.launch --throughput-mode --enable_tcmalloc --log_path=${OUTPUT_DIR} --log_file_prefix="./latency_log_${precision}_${mode}" \
  ${EVAL_SCRIPT} $ARGS \
  --model-name-or-path   ${FINETUNED_MODEL} \
  --max-new-tokens ${OUTPUT_TOKEN} \
  --input-tokens  ${INPUT_TOKEN} \
  --batch-size $BATCH_SIZE 

CORES_PER_INSTANCE=${OMP_NUM_THREADS}
TOTAL_CORES=`expr $CORES \* $SOCKETS`
INSTANCES=`expr $TOTAL_CORES / $CORES_PER_INSTANCE`
INSTANCES_PER_SOCKET=`expr $INSTANCES / $SOCKETS`


latency=($(grep -i 'inference-latency:' ${OUTPUT_DIR}/latency_${precision}* |sed -e 's/.*atency: //;s/[^0-9.]//g;s/\.$//' |awk '
        BEGIN {
            num = 0;
            sum = 0;
        }{
            num ++;
            sum += $1;
        }END {
            if(num > 0) {
                printf("%.6f", sum / num);
            }else {
                printf("0  0");
            }
        }
    '))
first_latency=($(grep -i 'first-token-latency:' ${OUTPUT_DIR}/latency_${precision}*  |sed -e 's/.*atency://;s/[^0-9.]//g;s/\.$//' |awk '
    BEGIN {
        num = 0;
        sum = 0;
    }{
        num ++;
        sum += $1;
    }END {
        if(num > 0) {
            printf("%.6f", sum / num);
        }else {
            printf("0");
        }
    }
'))
rest_token_latency=($(grep -i 'rest-token-latency:' ${OUTPUT_DIR}/latency_${precision}*  |sed -e 's/.*atency://;s/[^0-9.]//g;s/\.$//' |awk '
    BEGIN {
        num = 0;
        sum = 0;
    }{
        num ++;
        sum += $1;
    }END {
        if(num > 0) {
            printf("%.6f", sum / num);
        }else {
            printf("0");
        }
    }
'))
P90_rest_token_latency=($(grep -i 'P90-rest-token-latency:' ${OUTPUT_DIR}/latency_${precision}*  |sed -e 's/.*atency://;s/[^0-9.]//g;s/\.$//' |awk '
    BEGIN {
        num = 0;
        sum = 0;
    }{
        num ++;
        sum += $1;
    }END {
        if(num > 0) {
            printf("%.6f", sum / num);
        }else {
            printf("0");
        }
    }
'))


token_per_sec=($(awk -v output_token=$OUTPUT_TOKEN -v total=$latency -v batch=$BATCH_SIZE -v first_token=${first_latency}} '
    BEGIN {
        thp = batch*(output_token-1)/(total-first_token);
        printf("%.3f", thp);    
    }
'))

first_token_thp=($(awk -v output_token=$OUTPUT_TOKEN -v total=$latency -v batch=$BATCH_SIZE -v first_token=${first_latency}} '
    BEGIN {
        thp = batch*(1)/(first_token);
        printf("%.3f", thp);    
    }
'))
echo ""LLaMa";latency;"total-latency";${precision};${BATCH_SIZE}; ${latency} " |tee -a ${OUTPUT_DIR}/summary.log
echo ""LLaMa";latency;"first-token-latency";${precision};${BATCH_SIZE}; ${first_latency} " |tee -a ${OUTPUT_DIR}/summary.log
echo ""LLaMa";latency;"rest-token-latency";${precision};${BATCH_SIZE}; ${rest_token_latency} " |tee -a ${OUTPUT_DIR}/summary.log
echo ""LLaMa";latency;"P90-rest-token-latency";${precision};${BATCH_SIZE}; ${P90_rest_token_latency} " |tee -a ${OUTPUT_DIR}/summary.log
echo ""LLaMa";latency;"token_per_sec";${precision};${BATCH_SIZE}; ${token_per_sec} " |tee -a ${OUTPUT_DIR}/summary.log
echo ""LLaMa";latency;"first_token_thp";${precision};${BATCH_SIZE}; ${first_token_thp} " |tee -a ${OUTPUT_DIR}/summary.log
