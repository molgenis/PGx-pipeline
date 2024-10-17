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
protocol="${pipelineRoot}/protocols/concatenate_chromosomes.sh"
jobName="concatenate_chromosomes"

echo ${protocol}

# Now get all arrays over which jobs should be generated.

# Extract all values for which want to execute a job

declare -a arrayVariable=($(seq 1 22 ))

echo ${arrayVariable[@]}
# Number of tasks to execute

nTasks=0

echo "starting: ${nTasks}"

# For each of the tasks, write a param.sh file
for job_array_index in "${!arrayVariable[@]}"; do
  # Construct the job dir as follows
  chromosomeNumber="${arrayVariable[$job_array_index]}"
  # Write parameter file to the job dir
  eval genotypesPlinkPrefix=${_genotypesPlinkPrefix}
  genotypesPlinkPrefixArray+=($genotypesPlinkPrefix)
  # make parameter file
done

mkdir -p "${workdir}/${jobName}_0"

mkdir -p "${concatenatedGenotypesOutputDir}"
printf '%s=( %s)\n' "genotypesPlinkPrefixArray" "$(printf '%q ' "${genotypesPlinkPrefixArray[@]}")" > ${workdir}/${jobName}_0/params.sh

# Now start the slurm array job
sbatch \
  -J "${jobName}" \
  -D "${workdir}" \
  -o "${workdir}/%x_%a/slurm.out" \
  -e "${workdir}/%x_%a/slurm.err" \
  -a 0-${nTasks} \
  --time 00:59:00 \
  --cpus-per-task 2 \
  --mem 8gb \
  --nodes 1 \
  --export parameters=${parameters},protocol=${protocol} \
  ${molgenisStandInScript}
