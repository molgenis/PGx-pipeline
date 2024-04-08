#!/bin/bash

set -e
set -u

#Get command line options
while getopts ":p:" opt; do
  case "$opt" in
    p) parameters=$OPTARG ;;
  esac
done

parameters=$(realpath ${parameters})
# Source all parameters
source ${parameters}
# Define the protocol to run
protocol="${pipelineRoot}/protocols/cnv_genotype_call_integration.sh"

echo ${protocol}

# Extract all values for which want to execute a job

# We need to define the array final report, which I think is just the same value as
# it was in the previous step 1 job.

jobname="cnv_genotype_call_integration"

mkdir -p "${workdir}/${jobname}_1"
touch ${workdir}/${jobname}_1/params.sh

sbatch \
  -J "${jobname}" \
  -D "${workdir}" \
  -o "${workdir}/%x_%a/slurm.out" \
  -e "${workdir}/%x_%a/slurm.err" \
  -a 1-1 \
  --time 05:59:00 \
  --cpus-per-task 4 \
  --mem 16gb \
  --nodes 1 \
  --qos priority \
  --export parameters=${parameters},protocol=${protocol} \
  ${molgenisStandInScript}
