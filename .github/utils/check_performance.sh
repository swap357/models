#!/bin/bash

WORKLOAD=$1
PRECISION=$2
BENCHMARK_TYPE=$3
BENCHMARK_THRESHOLD=$4
TOLERANCE=$5

LOWER_LIMIT=$(echo "${BENCHMARK_THRESHOLD}*(1-${TOLERANCE})" | bc -l)
UPPER_LIMIT=$(echo "${BENCHMARK_THRESHOLD}*(1+${TOLERANCE})" | bc -l)

if [[ "${BENCHMARK_TYPE}" == "latency" ]] || [[ "${BENCHMARK_TYPE}" == "throughput" ]]; then
    BENCHMARK=$(cat ../../tests/cicd/${WORKLOAD}/output/${WORKLOAD}/${PRECISION}/*benchmark* | grep -i ${BENCHMARK_TYPE} | grep -Eo '[0-9]+\.[0-9]+{1,4}')
elif [[ "${BENCHMARK_TYPE}" == "accuracy" ]]; then
    BENCHMARK=$(cat ../../tests/cicd/${WORKLOAD}/output/${WORKLOAD}/${PRECISION}/*accuracy* | tail -n 3 |grep -i accuracy | grep -Eo '[0-9]+\.[0-9]+{1,4}' | tail -n 1)
fi

echo "## Performance Test ${WORKLOAD}-${BENCHMARK_TYPE}-${PRECISION}" >> $GITHUB_STEP_SUMMARY
if [[ "${BENCHMARK_TYPE}" == "latency" ]] && (( $(echo "${BENCHMARK} < ${UPPER_LIMIT}" | bc -l) )); then
    echo "PASS: ${BENCHMARK_TYPE} of ${BENCHMARK} has an acceptable tolerance ("${TOLERANCE}") compared to ${BENCHMARK_THRESHOLD} :white_check_mark:" >> $GITHUB_STEP_SUMMARY
elif [[ "${BENCHMARK_TYPE}" == "latency" ]] && (( $(echo "${BENCHMARK} >= ${UPPER_LIMIT}" | bc -l) )); then
    echo "FAIL: ${BENCHMARK_TYPE} of ${BENCHMARK} does not have an acceptable tolerance ("${TOLERANCE}") compared to ${BENCHMARK_THRESHOLD} :rotating_light:" >> $GITHUB_STEP_SUMMARY
elif [[ "${BENCHMARK_TYPE}" == "throughput" || "${BENCHMARK_TYPE}" == "accuracy" ]] && (( $(echo "${BENCHMARK} > ${LOWER_LIMIT}" | bc -l) )); then
    echo "PASS: ${BENCHMARK_TYPE} of ${BENCHMARK} has an acceptable tolerance ("${TOLERANCE}") compared to ${BENCHMARK_THRESHOLD} :white_check_mark:" >> $GITHUB_STEP_SUMMARY
elif [[ "${BENCHMARK_TYPE}" == "throughput" || "${BENCHMARK_TYPE}" == "accuracy" ]] && (( $(echo "${BENCHMARK} <= ${LOWER_LIMIT}" | bc -l) )); then
    echo "FAIL: ${BENCHMARK_TYPE} of ${BENCHMARK} does not have an acceptable tolerance ("${TOLERANCE}") compared to ${BENCHMARK_THRESHOLD} :rotating_light:" >> $GITHUB_STEP_SUMMARY
fi
