#MOLGENIS walltime=04:00:00 mem=2gb ppn=1
#string gtcDataDir
#string pgxVersion
#string samplesheet
#string ngsUtilsVersion
#string gapVersion
#string intermediateDir
set -eu

module load "${gapVersion}"

#
### Preprocess of this step is copy all the SentrixBarcodes folders to ${rawdataPath}/hematologie_research_data/${project}/ a.k.a ${gtcDataDir}
#

cd "${intermediateDir}"

bash "${EBROOTGAP}/nextflow/run_researchWorkflow.sh" -s "${samplesheet}" -g "${gtcDataDir}" -n "${EBROOTGAP}/nextflow/main.nf" -c 'yes' -r 'no' || {
	echo "something went wrong during the preprocessing script"
	echo "try to run it manually:"
	echo "${EBROOTGAP}/nextflow/run_researchWorkflow.sh -s \"${samplesheet}\" -g gtcDir \"${gtcDataDir}\" -n \"${EBROOTGAP}/nextflow/main.nf\" -c 'yes' -r 'no'"
	exit 1
	}
	
	rsync -rv "${intermediateDir}/results" "${gtcDataDir}/"
	
echo "finished"

cd -