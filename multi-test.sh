#!/bin/bash

# set default loops to 10
NUM_LOOPS="${1:-10}"

# set the default number of execs to 40
NUM_EXECS="${2:-40}"

# set default to not disable seccomp on the test container
DISABLE_SECCOMP="${DISABLE_SECCOMP:-false}"

# set default to be more verbose
VERBOSE="${VERBOSE:-true}"

# let user know what test we are doing
if [ "${VERBOSE}" = "true" ]
then
  echo "Running ${NUM_LOOPS} loops of ${NUM_EXECS} execs"
fi

# loop through the test
dpkg -l libseccomp2 | grep ^ii | awk '{print $1 "  " $2 " " $3 " " $4}' >> debug.out
dpkg -l docker-ee | grep ^ii | awk '{print $3}' >> debug.out
echo "DISABLE_SECCOMP=${DISABLE_SECCOMP}" >> debug.out

for LOOP in $(seq 1 "${NUM_LOOPS}")
do
  if [ "${VERBOSE}" = "true" ]
  then
    echo -e "\nLoop ${LOOP}"
  fi
  echo -e "\nLoop ${LOOP}" >> debug.out
  STATS="$(DISABLE_SECCOMP="${DISABLE_SECCOMP}" ./docker-libseccomp-test.sh "${NUM_EXECS}" | grep -E '(Min:)|(Max:)|(Avg:)')"
  echo "${STATS}" | grep Min >> stats_min.txt
  echo "${STATS}" | grep Max >> stats_max.txt
  echo "${STATS}" | grep Avg >> stats_avg.txt
  if [ "${VERBOSE}" = "true" ]
  then
    echo "${STATS}"
  fi
  echo "${STATS}" >> debug.out
done

# get averages of each stat
echo -e "\nAverage stats from ${NUM_LOOPS} loops of ${NUM_EXECS} execs on docker-ee=$(dpkg -l docker-ee | grep ^ii | awk '{print $3}') for libseccomp2=$(dpkg -l libseccomp2 | grep ^ii | awk '{print $3}') with DISABLE_SECCOMP=${DISABLE_SECCOMP}:"
echo "Avg Min: $(awk '{sum+=$2}END{printf "%0.2f\n",sum/NR}' stats_min.txt)"
echo "Avg Max: $(awk '{sum+=$2}END{printf "%0.2f\n",sum/NR}' stats_max.txt)"
echo "Avg Avg: $(awk '{sum+=$2}END{printf "%0.2f\n",sum/NR}' stats_avg.txt)"

# check to see if we need to write headers to the csv output
if [ ! -f "test_results.csv" ]
then
  echo "docker-ee version,libseccomp2 version,num_loops,num_execs,disable_seccomp,min,max,avg" > test_results.csv
fi

# write output to a log file
echo "docker-ee=$(dpkg -l docker-ee | grep ^ii | awk '{print $3}'),libseccomp2=$(dpkg -l libseccomp2 | grep ^ii | awk '{print $3}'),${NUM_LOOPS},${NUM_EXECS},${DISABLE_SECCOMP},$(awk '{sum+=$2}END{printf "%0.2f\n",sum/NR}' stats_min.txt),$(awk '{sum+=$2}END{printf "%0.2f\n",sum/NR}' stats_max.txt),$(awk '{sum+=$2}END{printf "%0.2f\n",sum/NR}' stats_avg.txt)" >> test_results.csv

# cleanup
rm stats_min.txt stats_max.txt stats_avg.txt
