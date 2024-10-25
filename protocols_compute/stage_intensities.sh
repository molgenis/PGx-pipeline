#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string pythonEnvironment
#string bpmFile
#string finalReport
#string stagedIntensitiesDir
#string stagedIntensities
#string samplesheet
#string sampleListPrefix
#string correctiveVariantsOutputDir
#string SentrixBarcode_A
#string asterixVersion

set -e
set -u

module load "${pythonVersion}"
module load "${asterixVersion}"
module list

source "${pythonEnvironment}/bin/activate"

mkdir -p "${stagedIntensitiesDir}"

rm -f "${stagedIntensities}"

python "${EBROOTASTERIX}/src/main/python/cnvcaller/core.py" data \
  --bead-pool-manifest "${bpmFile}" \
  --sample-list "${sampleListPrefix}.samples.txt" \
  --variants-prefix "${correctiveVariantsOutputDir}" \
  --final-report-file-path "${finalReport}" \
  --out "${stagedIntensities}" \
  --config "${EBROOTASTERIX}/src/main/python/cnvcaller/conf/config.yml"
