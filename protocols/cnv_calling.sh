#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string pythonEnvironment
#string bpmFile
#string pgxGenesBed37
#string cnvBedFile
#string pipelineRoot
#string arrayStagedIntensities
#string samplesheet

set -e
set -u

module load "${pythonVersion}"
module list

source ${pythonEnvironment}/bin/activate

mkdir -p ${cnvOutDir}

python ${asterixRoot}/src/main/python/cnvcaller/core.py fit \
  --bead-pool-manifest "${bpmFile}" \
  --sample-sheet "${samplesheet}" \
  --variants-prefix "${correctiveVariantsOutputDir}" \
  --out ${cnvOutDir} \
  --input ${arrayStagedIntensities[@]} \
  --config ${asterixRoot}/src/main/python/cnvcaller/conf/config.yml
