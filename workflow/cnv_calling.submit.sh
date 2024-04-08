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
protocol="${pipelineRoot}/protocols/cnv_calling.sh"

echo ${protocol}

# Extract all values for which want to execute a job

# We need to define the array final report, which I think is just the same value as
# it was in the previous step 1 job.

jobname="cnv_calling"

arrayStagedIntensities=("${stagedIntensities}/stage_intensities_*_intensities.pkl")

mkdir -p "${workdir}/${jobname}_1"
printf '%s=( %s)\n' "arrayStagedIntensities" "$(printf '%q ' "${arrayStagedIntensities[@]}")" > ${workdir}/${jobname}_1/params.sh

echo ${workdir}/${jobname}_1/params.sh
# Now start the slurm array job

sbatch \
  -J "${jobname}" \
  -D "${workdir}" \
  -o "${workdir}/%x_%a/slurm.out" \
  -e "${workdir}/%x_%a/slurm.err" \
  -a 1-1 \
  --time 00:59:00 \
  --cpus-per-task 1 \
  --mem 32gb \
  --nodes 1 \
  --export parameters=${parameters},protocol=${protocol} \
  ${molgenisStandInScript}
