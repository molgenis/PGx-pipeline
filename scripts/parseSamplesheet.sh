set -eu


#
## EXAMPLE MAPPING.CSV
#
# openarray_project	sampleId_OA	FGP_batch	sampleId_GSA
#FGP_001	FGP0205	2026-03_batch1_plusGDIO	FGP0205
#FGP_001	FGP0206	2026-03_batch1_plusGDIO	FGP0206
#FGP_001	FGP0207	2026-03_batch1_plusGDIO	FGP0207

#
## Copy openarray data to /groups/umcg-pgx/tmp07/concordance/ngs/
# 
#


path="/groups/umcg-pgx/tmp07/concordance/ngs/"
pathTmp="/groups/umcg-pgx/tmp07/concordance/tmp/"

count=0

while read line 
do
	oaProject=$(echo "${line}" | awk 'BEGIN {FS="\t"}{print $1}')
	oaSample=$(echo "${line}" | awk 'BEGIN {FS="\t"}{print $2}')
	fgpProject=$(echo "${line}" | awk 'BEGIN {FS="\t"}{print $3}')
	fgpSample=$(echo "${line}" | awk 'BEGIN {FS="\t"}{print $4}')
	if [[ "${count}" == 0 ]]
	then
		echo  "skip header"
		count=1
	else
		rsync -v "/groups/umcg-pgx/tmp07/projects/${fgpProject}/results/vcf/"*"${fgpSample}"*.vcf.gz "${path}"

		readarray -t fgpsampleArray< <(find "${path}" -name *"${fgpSample}"*.vcf.gz)
		readarray -t oasampleArray< <(find "${path}" -name *"${fgpSample}"*.oarray.txt)
		if [[ "${#fgpsampleArray[@]}" -eq '0' ]]
		then
			echo "errorTerror, no fgpsample with vcf.gz extension found in ${path}"
			exit 1
		elif [[ "${#fgpsampleArray[@]}" -gt '1' ]]
		then

			echo "errorTerror, more than 1 fgpsample with vcf.gz extension found in ${path}"
			exit 1
		fi
		if [[ "${#oasampleArray[@]}" -eq '0' ]]
		then
			echo "errorTerror, no oasample with oarray.txt extension found in ${path}"
			exit 1
		elif [[ "${#oasampleArray[@]}" -gt '1' ]]
		then
			echo "errorTerror, more than 1 oasample with oarray.txt extension found in ${path}"
			exit 1
		fi
		oasampleFile="${oasampleArray[0]}"
		fgpsampleFile="${fgpsampleArray[0]}"
		oaSampleId=$(basename "${oasampleFile}")
		oaSampleId="${oaSampleId%%.*}"
		echo -e "data1Id\tdata2Id\tlocation1\tlocation2\tfileType1\tfileType2\tbuild1\tbuild2\tproject1\tproject2\tfileprefix\tprocessStepId" > "${pathTmp}/123456_${fgpProject}_${fgpSample}_${oaProject}_${oaSampleId}.sampleId.txt"
		echo -e "${fgpSample}\t${oaSampleId}\t${fgpsampleFile}\t${oasampleFile}\tPGX\tOPENARRAY\tGRCh37\tGRCh37\t${fgpProject}\t${oaProject}\t123456_${fgpProject}_${fgpSample}_${oaProject}_${oaSampleId}\t123456" >> "${pathTmp}/123456_${fgpProject}_${fgpSample}_${oaProject}_${oaSampleId}.sampleId.txt"

		cp "${pathTmp}/123456_${fgpProject}_${fgpSample}_${oaProject}_${oaSampleId}.sampleId.txt" "/groups/umcg-pgx/tmp07/concordance/samplesheets/"
	fi
done<mapping.csv