#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string asterixVersion
#string pgxVersion
#string pythonEnvironment
#string bpmFile
#string pgxGenesBed37
#string cnvBedFile
#list stagedIntensities
#string sampleListPrefix
#string cnvOutDir
#string correctiveVariantsOutputDir
#string cnvBatchCorrectionPath

set -e
set -u

#Function to check if array contains value
array_contains () {
	local array="$1[@]"
	local seeking="${2}"
	local in=1
	for element in "${!array-}"; do
		if [[ "${element}" == "${seeking}" ]]; then
			in=0
			break
		fi
	done
	return "${in}"
}

# Now load the python version and activate the python environment
# to perform cnv calling
module load "${pythonVersion}"
module load "${asterixVersion}"
module load "${pgxVersion}"
module list

INPUTS=()

for stageInt in "${stagedIntensities[@]}"
do
	array_contains INPUTS "${stageInt}" || INPUTS+=("${stageInt}")    # If bamFile does not exist in array add it

done

mkdir -p "${cnvOutDir}"

source ${pythonEnvironment}/bin/activate

python "${EBROOTASTERIX}/src/main/python/cnvcaller/core.py" call \
  --bead-pool-manifest "${bpmFile}" \
  --sample-list "${sampleListPrefix}.samples.txt" \
  --variants-prefix "${correctiveVariantsOutputDir}" \
  --out "${cnvOutDir}" \
  --input "${INPUTS[@]}" \
  --cluster-file "${cnvBatchCorrectionPath}" \
  --config "${EBROOTPGX}/data/cyp2d6/config.yml"
