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
protocol="${pipelineRoot}/protocols/imputation_pipeline.sh"
jobName="impute_pgx_genes"

echo ${protocol}

# Now get all arrays over which jobs should be generated.

# Extract all values for which want to execute a job

# Number of tasks to execute

nTasks=0

mkdir -p "${workdir}/${jobName}_${nTasks}"
touch "${workdir}/${jobName}_${nTasks}/params.sh"

echo "starting: ${nTasks}"

# Now start the slurm array job
sbatch \
  -J "${jobName}" \
  -D "${workdir}" \
  -o "${workdir}/%x_%a/slurm.out" \
  -e "${workdir}/%x_%a/slurm.err" \
  -a 0-${nTasks} \
  --time 23:59:00 \
  --cpus-per-task 2 \
  --mem 4gb \
  --nodes 1 \
  --export parameters=${parameters},protocol=${protocol} \
  ${molgenisStandInScript}
