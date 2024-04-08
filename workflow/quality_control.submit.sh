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
protocol="${pipelineRoot}/protocols/variant_filtering.sh"
jobName="variant_filtering"

echo ${protocol}

# Now get all arrays over which jobs should be generated.

# Extract all values for which want to execute a job

declare -a arrayVariable=($(seq 1 22 ) "X")

echo ${arrayVariable[*]}
# Number of tasks to execute

nTasks=$(expr ${#arrayVariable[@]} - 1)

echo "starting: ${nTasks}"

# For each of the tasks, write a param.sh file
for job_array_index in "${!arrayVariable[@]}"; do
  # Construct the job dir as follows
  jobdir="${workdir}/${jobName}_${job_array_index}/"

  echo $jobdir

  # Make the job dir
  mkdir -p ${jobdir}

  chromosomeNumber="${arrayVariable[$job_array_index]}"

  # Write parameter file to the job dir
  echo "# Parameter file for array index ${job_array_index}" > ${jobdir}/params.sh
  echo "jobName=${jobName}" >> ${jobdir}/params.sh
  echo "chromosomeNumber=${chromosomeNumber}" >> ${jobdir}/params.sh
  echo "genotypesOxfordPrefix=${_genotypesOxfordPrefix}" >> ${jobdir}/params.sh
  echo "genotypesPlinkPrefix=${_genotypesPlinkPrefix}" >> ${jobdir}/params.sh

done

# Now start the slurm array job
sbatch \
  -J "${jobName}" \
  -D "${workdir}" \
  -o "${workdir}/%x_%a/slurm.out" \
  -e "${workdir}/%x_%a/slurm.err" \
  -a 0-${nTasks} \
  --time 05:59:00 \
  --cpus-per-task 2 \
  --mem 8gb \
  --nodes 1 \
  --export parameters=${parameters},protocol=${protocol} \
  ${molgenisStandInScript}