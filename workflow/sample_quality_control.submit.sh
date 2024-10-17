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
protocol="${pipelineRoot}/protocols/sample_filtering.sh"
jobName="sample_quality_control"

echo ${protocol}

# Now get all arrays over which jobs should be generated.

# Extract all values for which want to execute a job

# Number of tasks to execute

nTasks=0

mkdir -p "${workdir}/${jobName}_${nTasks}"
touch "${workdir}/${jobName}_${nTasks}/params.sh"

echo "starting: ${nTasks}"

#SLURM_JOB_NAME=${jobName}
#SLURM_ARRAY_TASK_ID=0
#cd ${workdir}
#source ${molgenisStandInScript}
#cd -

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
