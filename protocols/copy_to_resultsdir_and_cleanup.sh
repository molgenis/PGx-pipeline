#MOLGENIS walltime=23:59:00 mem=2gb nodes=1 ppn=4

#string outputName
#string intermediateDir
#string cnvOutDir
#string resultsDir
#string sampleListPrefix
#string imputationOutputDir
#string gtcDataDir
#string tmpDataDir
#string projectDir
#string project
#string logsDir
#string intermediateDir

set -e
set -u

cnvDir=$(dirname "${cnvOutDir}")
qualControlledDir=$(dirname "${sampleListPrefix}")

chmod 755 -R ${imputationOutputDir}/*
rsync -rv "${cnvDir%/}" "${resultsDir}"
rsync -rv "${imputationOutputDir%/}" "${resultsDir}"
rsync -rv "${qualControlledDir%/}" "${resultsDir}"

mkdir -p "${resultsDir}/vcf/"

for i in "${gtcDataDir}/results/vcf/"*'FGP'*'.vcf.gz'
do
	rsync -v "${i}"* "${resultsDir}/vcf"
done

#
## Split research samples from FGP samples  
#
module load PLINK/1.9-beta6-20190617
oxfordFolder="${intermediateDir}/results/oxford_gen_sample"
sampleReadFile="${oxfordFolder}/chr_1.sample"

count=0
while read line
do
	if [[ ${count} -gt 1 ]]
	then
		
		identifier=$(echo "${line}" | awk 'BEGIN {FS=" "}{print $1}')
		
		if [[ "${identifier}" == *"FGP"* ]]
		then
			
			echo -e "${identifier} ${identifier}" >> "${oxfordFolder}/keep_FGP.txt"
		elif [[ "${identifier}" != *"GDIO"* ]]
		then
			echo -e "${identifier} ${identifier}" >> "${oxfordFolder}/keep_non_FGP.txt"
		fi
	else
		count=$((${count}+1))
	fi
done<"${sampleReadFile}"



mkdir -p "${oxfordFolder}/out"
for i in "${oxfordFolder}/"*".gen"
do
	outputFilename="$(basename ${i})"
	outputname=${outputFilename%.*}
	dataname=${i%.*}

	plink --data "${dataname}" \
	--keep "${oxfordFolder}/keep_non_FGP.txt" \
	--allow-no-sex \
	--make-bed  \
	--out "${oxfordFolder}/out/${outputname}"
done

chmod g+w "${projectDir}"
rsync -rv "${projectDir}" "tunnel+nibbler:/groups/umcg-pgx/tmp02/projects/"

echo "creating ${tmpDataDir}/logs/${project}/run01.pipeline.finished"
rm -f "${tmpDataDir}/logs/${project}/run01.pipeline.started"
rm -f "${tmpDataDir}/logs/${project}/run01.pipeline.failed"
touch "${tmpDataDir}/logs/${project}/run01.pipeline.finished"

