#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string pythonEnvironment
#string bpmFile
#string pgxGenesBed37
#string pipelineRoot
#string arrayStagedIntensities
#string samplesheet

set -e
set -u

module load "${pythonVersion}"
module list

source ${pythonEnvironment}/bin/activate

mkdir -p ${cnvOutDir}

awk '$4 == "CYP2D6" {print $0}' "${pgxGenesBed37}" > "cyp2d6.bed"

python ${asterixRoot}/src/main/python/cnvcaller/core.py correction fit \
  --bead-pool-manifest "${bpmFile}" \
  --sample-sheet "${samplesheet}" \
  --bed-file "cyp2d6.bed" \
  --corrective-variants "${correctiveVariantsOutputDir}/merged.prune.in" \
  --correction "${cnvOutDir}" \
  --cluster-file "${cnvOutDir}" \
  --input ${arrayStagedIntensities[@]}
