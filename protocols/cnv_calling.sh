#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string pythonEnvironment
#string bpmFile
#string pipelineRoot
#string arrayStagedIntensities
#string samplesheet

set -e
set -u

module load "${pythonVersion}"
module list

source ${pythonEnvironment}/bin/activate

mkdir -p ${cnvOutDir}

python - correction fit \
  --bead-pool-manifest "${bpmFile}" \
  --sample-sheet "${samplesheet}" \
  --bed-file "${cnvBedFile}" \
  --corrective-variants "${correctiveVariantsOutputDir}/merged.prune.in" \
  --input ${arrayStagedIntensities[@]} \
  --out "${cnvOutDir}"
