#!/bin/bash

WORKLOAD=$1
PRECISION=$2
BENCHMARK_TYPE=$3
BENCHMARK_THRESHOLD=$4

if [ "${PRECISION}" != "" ]; then
    BENCHMARK=$(cat ../../tests/cicd/${WORKLOAD}/output/${PRECISION}/benchmark* | grep -i ${BENCHMARK_TYPE} | grep -Eo '[0-9]+\.[0-9]+{1,4}')
    echo "## Performance Test ${WORKLOAD}-${BENCHMARK_TYPE}-${PRECISION}" >> $GITHUB_STEP_SUMMARY
    if [[ "${BENCHMARK_TYPE}" == "latency" ]] && (( $(echo "${BENCHMARK} < ${BENCHMARK_THRESHOLD}" | bc -l) )); then
        echo "PASS: ${BENCHMARK_TYPE} of ${BENCHMARK} ms is lower than ${BENCHMARK_THRESHOLD} :white_check_mark:" >> $GITHUB_STEP_SUMMARY
    elif [[ "${BENCHMARK_TYPE}" == "latency" ]] && (( $(echo "${BENCHMARK} >= ${BENCHMARK_THRESHOLD}" | bc -l) )); then
        echo "FAIL: ${BENCHMARK_TYPE} of ${BENCHMARK} ms is not lower than ${BENCHMARK_THRESHOLD} :rotating_light:" >> $GITHUB_STEP_SUMMARY
    elif [[ "${BENCHMARK_TYPE}" == "throughput" ]] && (( $(echo "${BENCHMARK} > ${BENCHMARK_THRESHOLD}" | bc -l) )); then
        echo "PASS: ${BENCHMARK_TYPE} of ${BENCHMARK} images/sec is higher than ${BENCHMARK_THRESHOLD} :white_check_mark:" >> $GITHUB_STEP_SUMMARY
    elif [[ "${BENCHMARK_TYPE}" == "throughput" ]] && (( $(echo "${BENCHMARK} <= ${BENCHMARK_THRESHOLD}" | bc -l) )); then
        echo "FAIL: ${BENCHMARK_TYPE} of ${BENCHMARK} images/sec is not higher than ${BENCHMARK_THRESHOLD} :rotating_light:" >> $GITHUB_STEP_SUMMARY
    fi
fi
