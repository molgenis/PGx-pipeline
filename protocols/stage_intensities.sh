#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string pythonEnvironment
#string bpmFile
#string pipelineRoot
#string arrayFinalReport
#string arrayStagedIntensities
#string samplesheet
#string SentrixBarcode_A

set -e
set -u

module load "${pythonVersion}"
module list

source ${pythonEnvironment}/bin/activate

mkdir -p ${stagedIntensities}

python ${asterixRoot}/src/main/python/cnvcaller/core.py stage-data\
--bead-pool-manifest "${bpmFile}" \
--sample-sheet "${samplesheet}" \
--bed-file "${cnvBedFile}" \
--corrective-variants "${correctiveVariantsOutputDir}/merged.prune.in" \
--final_report_file_path ${arrayFinalReport} \
--out "${arrayFinalReport}"
