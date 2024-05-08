#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string pythonEnvironment
#string bpmFile
#string gtcDataDir
#string pipelineRoot
#string arrayFinalReport
#string samplesheet
#string SentrixBarcode_A

set -e
set -u

module load "${pythonVersion}"
module list

source ${pythonEnvironment}/bin/activate

mkdir -p ${finalReportsDir}

rm -f "${arrayFinalReport}"

python ${pipelineRoot}/scripts/gtc_final_report.py \
--manifest "${bpmFile}" \
--samplesheet "${samplesheet}" \
--gtc_directory "${gtcDataDir}/${SentrixBarcode_A}/" \
--output_file "${arrayFinalReport}"

gzip -f "${arrayFinalReport}"
