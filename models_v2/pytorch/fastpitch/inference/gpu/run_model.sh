#
# -*- coding: utf-8 -*-
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
# SPDX-License-Identifier: EPL-2.0
#

#!/bin/bash

# Create an array of input directories that are expected and then verify that they exist
declare -A input_envs
input_envs[DATASET_DIR]=${DATASET_DIR}
input_envs[OUTPUT_DIR]=${OUTPUT_DIR}
input_envs[MULTI_TILE]=${MULTI_TILE}
input_envs[PLATFORM]=${PLATFORM}

for i in "${!input_envs[@]}"; do
  var_name=$i
  env_param=${input_envs[$i]}

  if [[ -z $env_param ]]; then
    echo "The required environment variable $var_name is not set" >&2
    exit 1
  fi
done

if [[ "${PLATFORM}" == "Max" ]]; then
    echo "Only support Flex for platform"
elif [[ "${PLATFORM}" == "Flex" ]]; then
    BATCH_SIZE=${BATCH_SIZE:-8}
    PRECISION=${PRECISION:-FP16}
    if [[ "${PRECISION}" != "FP16" ]]; then
      echo "FastPitch currently supports on FP16 precision" 
      exit 1
		fi
    NUM_ITERATIONS=${NUM_ITERATIONS:-100}
fi

if [[ ! -d "${DATASET_DIR}" ]]; then
    echo "The DATASET_DIR '${DATASET_DIR}' does not exist"
    exit 1
fi

if [[ ! -d "${CKPT_DIR}" ]]; then
    echo "The DATASET_DIR '${CKPT_DIR}' does not exist"
    exit 1
fi


if [[ "${MULTI_TILE}" == "True" ]]; then
    echo "only support MULTI_TILE=False"
    exit 1
fi

#CMUDICT_DIR=${CMUDICT_DIR:-"cmudict"}

# if [ ! -f $CMUDICT_DIR/cmudict-0.7b ]; then
#   echo "Downloading cmudict-0.7b ..."
#   wget https://github.com/Alexir/CMUdict/raw/master/cmudict-0.7b -qO $CMUDICT_DIR/cmudict-0.7b
# fi

echo 'Running with parameters:'
echo " PLATFORM: ${PLATFORM}"
echo " OUTPUT_DIR: ${OUTPUT_DIR}"
echo " DATASET_DIR: ${DATASET_DIR}"
echo " CKPT_DIR: ${CKPT_DIR}"
echo " PRECISION: ${PRECISION}"
echo " BATCH_SIZE: ${BATCH_SIZE}"
echo " MULTI_TILE: ${MULTI_TILE}"
echo " NUM_ITERATIONS: ${NUM_ITERATIONS}"

echo "Fastpitch ${PRECISION} inference plain MultiTile=${MULTI_TILE} BS=${BATCH_SIZE} Iter=${NUM_ITERATIONS}"

# Create the output directory, if it doesn't already exist
mkdir -p $OUTPUT_DIR

sum_log_analysis() {
    if [ -f $2 ]; then
        rm -f $2
    fi
    if diff /dev/null ${1}_t0.log |tail -l | grep '^\\ No newline' > /dev/null;then echo >> ${1}_t0.log; fi
    if diff /dev/null ${1}_t1.log |tail -l | grep '^\\ No newline' > /dev/null;then echo >> ${1}_t1.log; fi
    bs=$(cat ${1}_t1.log |grep Batch |awk '{print $3}')
    echo -e "Batch Size: $bs" >$2
    cat ${1}"_t0.log" ${1}"_t1.log" |grep "Performance" |awk -v tag=$(cat ${1}"_t0.log" ${1}"_t1.log" |grep "Performance" |awk '{sum+=$2} END {printf "%.4f\n",sum}') '{if ( $2=="None" ) {sum="None";nextfile}else  sum=tag} ;END{print "Sum "$1" "sum " "$3}' >> $2
    cat ${1}"_t0.log" ${1}"_t1.log" |grep "Performance" |awk -v tag=$(cat ${1}"_t0.log" ${1}"_t1.log" |grep "Performance" |awk 'BEGIN {min=1234567890123} {if ($2 <min) {min=$2}}END {printf "%.4f\n",min}') '{if ( $2=="None" ) {min="None";nextfile}else  min=tag} ;END{print "Min "$1" "min " "$3}' >> $2
    cat ${1}"_t0.log" ${1}"_t1.log" |grep "Latency" |awk '{if ( $2=="N/A" ){avg="N/A";nextfile}else avg=((sum+=$2/2))};END{print "Avg "$1" "avg " "$3}'  >> $2
    cat ${1}"_t0.log" ${1}"_t1.log" |grep "Accuracy" |awk -v avg=$(cat ${1}"_t0.log" ${1}"_t1.log" |grep "Accuracy" |awk '{sum+=$3}END{printf "%.4f\n",sum/NR}') '{if ( $3=="None" || $2=="N/A" || $3=="nan" || $3=="N/A"){avg="None";nextfile}else avg=avg};END{print "Avg "$1" "$2 " "avg}' >> $2
    cat ${1}"_t0.log" ${1}"_t1.log" |grep "Functional" | awk -v fail=$(cat ${1}"_t0.log" ${1}"_t1.log" |grep "Functional" |awk '{for(i=1;i<=NF;++i) if($i=="fail") ++sum}END{print sum}') '{if ( fail >= 1 ) tag="fail ";else tag="pass"};END{print $1" "tag}'  >> $2
    cat ${1}"_t0.log" ${1}"_t1.log" |grep "Error" |awk '{if(a[$1]){a[$1]=a[$1]";"$2}else{a[$1]=$2}}END{for(i in a)print $1" " a[i]}' >> $2
}

modelname=fast_pitch

if [[ ${MULTI_TILE} == "False" ]]; then
    rm ${OUTPUT_DIR}/${modelname}_${PRECISION}_inf_t0_raw.log
    python inference.py --fastpitch ${CKPT_DIR}/fastpitch/nvidia_fastpitch_210824.pt --hifigan ${CKPT_DIR}/hifigan/hifigan_gen_checkpoint_6500.pt --energy-conditioning  -i phrases/devset10.tsv  -o ${OUTPUT_DIR} --report-mel-loss --dataset-path ${DATASET_DIR} --xpu --repeats ${NUM_ITERATIONS} 2>&1 | tee ${OUTPUT_DIR}/${modelname}_${PRECISION}_inf_t0_raw.log
    python common/parse_result.py -m $modelname -l ${OUTPUT_DIR}/${modelname}_${PRECISION}_inf_t0_raw.log -b ${BATCH_SIZE}
    throughput=$(cat ${OUTPUT_DIR}/${modelname}_${PRECISION}_inf_t0.log | grep Performance | awk -F ' ' '{print $2}')
    throughput_unit=$(cat ${OUTPUT_DIR}/${modelname}_${PRECISION}_inf_t0.log | grep Performance | awk -F ' ' '{print $3}')
    latency=$(cat ${OUTPUT_DIR}/${modelname}_${PRECISION}_inf_t0.log | grep Latency | awk -F ' ' '{print $2}')
    acc=$(cat ${OUTPUT_DIR}/${modelname}_${PRECISION}_inf_t0.log | grep Accuracy | awk -F ' ' '{print $3}')
    acc_unit=$(cat ${OUTPUT_DIR}/${modelname}_${PRECISION}_inf_t0.log | grep Accuracy | awk -F ' ' '{print $2}')
else
    echo "Only support MULTI_TILE=False"
    exit 1
fi

yaml_content=$(cat <<EOF
results:
 - key: throughput
   value: $throughput
   unit: $throughput_unit
 - key: latency
   value: $latency
   unit: s
 - key: accuracy
   value: $acc
   unit: $acc_unit
EOF
)

# Write the content to a YAML file
echo "$yaml_content" >  ${OUTPUT_DIR}/results.yaml
echo "YAML file created."
