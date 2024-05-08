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
protocol="${pipelineRoot}/protocols/stage_intensities.sh"
jobName="stage_intensities"

echo ${protocol}

# Now read the samplesheet. Loop through all SentrixBarcode_A values
# Process samplesheet, write all unique SentrixBarcode_A values to a separate file

# Extract all values for which want to execute a job

# Get the index of the column with the sentrixbarcodes
sentrixBarcodeIndex=$(head -1 ${samplesheet} | tr -s ',' '\n' | nl -nln |  grep "SentrixBarcode_A" | cut -f1)
# Extract all unique barcodes
declare -a arrayVariable=($(cut -f${sentrixBarcodeIndex} -d',' ${samplesheet} | tail -n +2 | sort | uniq ))
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

  SentrixBarcode_A="${arrayVariable[$job_array_index]}"

  # Write parameter file to the job dir
  echo "# Parameter file for array index ${job_array_index}" > ${jobdir}/params.sh
  echo "jobName=${jobName}" >> ${jobdir}/params.sh
  echo "SentrixBarcode_A=${SentrixBarcode_A}" >> ${jobdir}/params.sh
  echo 'arrayFinalReport=${finalReportsDir}/process_gtc_${SentrixBarcode_A}_finalreport.txt.gz' >> ${jobdir}/params.sh
  echo 'arrayStagedIntensities=${stagedIntensities}/${jobName}_${SentrixBarcode_A}_intensities.pkl' >> ${jobdir}/params.sh

  # make parameter file
done

# Now start the slurm array job

sbatch \
  -J "${jobName}" \
  -D "${workdir}" \
  -o "${workdir}/%x_%a/slurm.out" \
  -e "${workdir}/%x_%a/slurm.err" \
  -a 0-${nTasks} \
  --time 00:59:00 \
  --cpus-per-task 2 \
  --mem 4gb \
  --nodes 1 \
  --export parameters=${parameters},protocol=${protocol} \
  ${molgenisStandInScript}
