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
#list SentrixPosition_A
#list Sample_ID

set -e
set -u

module load "${pythonVersion}"
module load "${beadArrayVersion}"
module load "${pgxVersion}"
module list

makeTmpDir "${arrayFinalReport}"
tmpArrayFinalReport="${MC_tmpFile}"

python ${EBROOTPGXMINUSPIPELINE}/scripts/gtc_final_report_diagnostics.py "${bpmFile}" "${projectRawTmpDataDir}" "${tmpArrayFinalReport}"



samples=()
count=0

barcodelist=()

n_elements=${Sample_ID[@]}
max_index=${#Sample_ID[@]}-1


for ((samplenumber = 0; samplenumber <= max_index; samplenumber++))
do
	barcodelist+=("${Sample_ID[samplenumber]}:${SentrixBarcode_A[samplenumber]}_${SentrixPosition_A[samplenumber]}")
done


for i in ${barcodelist[@]}
do
	echo "processing $i"
	echo "countboven: $count"
	sampleName=$(echo ${i} | awk 'BEGIN {FS=":"}{print $1}')
	barcodeCombined=$(echo ${i} | awk 'BEGIN {FS=":"}{print $2}')
	echo ${sampleName}
	echo ${barcodeCombined}

	echo "mv ${tmpArrayFinalReport}/concordance_${barcodeCombined}.gtc.txt ${tmpArrayFinalReport}/${sampleName}.txt"
	mv "${tmpArrayFinalReport}/concordance_${barcodeCombined}.gtc.txt" "${tmpArrayFinalReport}/${sampleName}.txt"
	echo  "mv ${tmpArrayFinalReport}/${sampleName}.txt ${arrayFinalReport}"
	mv "${tmpArrayFinalReport}/${sampleName}.txt" "${arrayFinalReport}"

	echo "countonder: $count"
	count=$((count+1))
done
