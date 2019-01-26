#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string beadArrayVersion
#string pgxVersion
#string bpmFile
#string projectRawTmpDataDir
#string intermediateDir
#string tmpTmpdir
#string tmpDir
#string workDir
#string tmpName
#string Project
#string logsDir
#string arrayFinalReport
#list SentrixBarcode_A

set -e
set -u

module load "${pythonVersion}"
module load "${beadArrayVersion}"
module load "${pgxVersion}"
module list

makeTmpDir "${arrayFinalReport}"
tmpArrayFinalReport="${MC_tmpFile}"

python ${EBROOTPGXMINUSPIPELINE}/scripts/gtc_final_report_diagnostics.py "${bpmFile}" "${projectRawTmpDataDir}" "${tmpArrayFinalReport}"



echo "mv ${tmpArrayFinalReport} ${arrayFinalReport}"
mv "${tmpArrayFinalReport}" "${arrayFinalReport}"
