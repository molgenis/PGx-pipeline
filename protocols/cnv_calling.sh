#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string pythonEnvironment
#string bpmFile
#string pgxGenesBed37
#string cnvBedFile
#string pipelineRoot
#string arrayStagedIntensities
#string sampleListPrefix

set -e
set -u

# Now load the python version and activate the python environment
# to perform cnv calling
module load "${pythonVersion}"
module list

source ${pythonEnvironment}/bin/activate

python ${asterixRoot}/src/main/python/cnvcaller/core.py call \
  --bead-pool-manifest "${bpmFile}" \
  --sample-list "${sampleListPrefix}.samples.txt" \
  --variants-prefix "${correctiveVariantsOutputDir}" \
  --out "${cnvOutDir}" \
  --input "${arrayStagedIntensities[@]}" \
  --correction "${cnvBatchCorrectionPath}" \
  --cluster-file "${cnvBatchCorrectionPath}" \
  --config ${asterixRoot}/src/main/python/cnvcaller/conf/config.yml
