set -eu

function showHelp() {
	#
	# Display commandline help on STDOUT.
	#
	cat <<EOH
===============================================================================================================
Script that prepares PGx pipeline 
Usage:
	$(basename "${0}") OPTIONS
Options:
	-h   Show this help.
	-p   projectName
	-g   glaasje (space seperated if there are multiple) NOTE: provide this argument last

===============================================================================================================
EOH
	trap - EXIT
	exit 0
}


while getopts "p:h" opt; 
do
	case "${opt}" in h)showHelp;; p)projectName="${OPTARG}";; g)glaasjes="${OPTARG}";; 
esac 
done

if [[ -z "${projectName:-}" ]]; then showHelp ; echo "projectName is not specified" ; fi ; echo "projectName=${projectName}"

tmpdir="/groups/umcg-pgx/tmp07/"
samplesheetFolder="${tmpdir}/Samplesheets/"
rawdata="${tmpdir}/rawdata/hematologie_research_data"


if [[ ! -f "${samplesheetFolder}/${projectName}.csv" ]]
then
  echo "samplesheet should be here: ${samplesheetFolder}/${projectName}.csv"
	exit 1
fi


mkdir -p "${rawdata}/${projectName}"
cd "${rawdata}/${projectName}"

echo "step1: make symlinks for new data"

declare -a _sampleSheetColumnNames=()
declare -A _sampleSheetColumnOffsets=()

IFS="," read -r -a _sampleSheetColumnNames <<< "$(head -1 ${samplesheetFolder}/${projectName}.csv)"

for (( _offset = 0 ; _offset < ${#_sampleSheetColumnNames[@]} ; _offset++ ))
do
	_sampleSheetColumnOffsets["${_sampleSheetColumnNames[${_offset}]}"]="${_offset}"
done
 
if [[ -n "${_sampleSheetColumnOffsets['SentrixBarcode_A']+isset}" ]]; then
  sentrixBarcodeAFieldIndex=$((${_sampleSheetColumnOffsets['SentrixBarcode_A']} + 1))
fi 
if [[ -n "${_sampleSheetColumnOffsets['SentrixPosition_A']+isset}" ]]; then
  SentrixPositionAFieldIndex=$((${_sampleSheetColumnOffsets['SentrixPosition_A']} + 1))
fi

if [[ -n "${_sampleSheetColumnOffsets['Sample_ID']+isset}" ]]; then
  sampleIDFieldIndex=$((${_sampleSheetColumnOffsets['Sample_ID']} + 1))
fi


module load gtc2vcf
count=0

projectNameGDIO="${projectName}_plusGDIO"
samplesheet="${samplesheetFolder}/${projectNameGDIO}.csv"

mkdir -p "${rawdata}/${projectNameGDIO}/results/vcf/"
rm -f *'_samples.txt'

mkdir -p "${rawdata}/${projectNameGDIO}/results/vcf/"

while read line
do
	if [[ "${count}" == 0 ]]
	then
		count=1
	else

		gtcFile=$(echo "${line}" | awk -v sb="${sentrixBarcodeAFieldIndex}" -v sp="${SentrixPositionAFieldIndex}" 'BEGIN {FS=","}{print $sb"_"$sp".gtc"}')
		glaasje=$(echo "${line}" | awk -v sb="${sentrixBarcodeAFieldIndex}" 'BEGIN {FS=","}{print $sb}')
		sampleID=$(echo "${line}" | awk -v sid="${sampleIDFieldIndex}" 'BEGIN {FS=","}{print $sid}')
		mkdir -p "${rawdata}/${projectName}/${glaasje}"
		rsync -v "/groups/umcg-pgx/tmp07/rawdata/gtc/${glaasje}/${gtcFile}" "${rawdata}/${projectName}/${glaasje}/"
		echo "${glaasje}" >> 'glaasjes.txt'
		echo -e "${gtcFile%.gtc} ${sampleID}" >> "${glaasje}_samples.txt"

	fi
done<"${samplesheetFolder}/${projectName}.csv"
echo "first making vcf files"

sort -V 'glaasjes.txt' | uniq > 'uniqglaasjes.txt'
out_prefix="${rawdata}/${projectNameGDIO}/results/vcf/"
ref="/apps/data/1000G/phase1/human_g1k_v37_phiX.fasta"
bpm_manifest_file="/apps/data/GSAarray/GSAMD-24v3-0-EA_20034606_A1.bpm"

# gtc to vcf	
while read glaasje
do
	echo "processing ${glaasje}.."

	path_to_gtc_folder="${rawdata}/${projectName}/${glaasje}/"
	
	bcftools +gtc2vcf -g "${path_to_gtc_folder}" -b "${bpm_manifest_file}" -f "${ref}"  | \
	bcftools reheader --samples "${glaasje}_samples.txt" | \
	bcftools sort -Ou -T ./bcftools. | \
	bcftools norm --no-version -o "${out_prefix}/${glaasje}_first_output.bcf" -Ob -c x -f "${ref}"

	echo "${glaasje} done"

done<'uniqglaasjes.txt'

# split vcf per sample
while read glaasje
do
	bcftools +split "${out_prefix}/${glaasje}_first_output.bcf" -o "${out_prefix}"
done<'uniqglaasjes.txt'

# bgzip + index
for i in $(ls "${out_prefix}/"*'.vcf')
do
	bgzip -f "${i}"
	tabix -f -p vcf "${i}.gz"
done

projectNameGDIO="${projectName}_plusGDIO"
samplesheet="${samplesheetFolder}/${projectNameGDIO}.csv"

mkdir -p "${rawdata}/${projectNameGDIO}"
cd "${rawdata}/${projectNameGDIO}"
echo "step1: make symlinks for new data + GDIO"

ln -sf "../${projectName}"/* .
ln -sf "../../GDIO/GTC/"* .

cd "${samplesheetFolder}"
cat "${samplesheetFolder}/${projectName}.csv" "${tmpdir}/rawdata/GDIO/GDIO.csv" > "${samplesheet}"
wc -l "${samplesheet}"
echo "combining samplesheet with GDIO samplesheet"
perl -pi -e 's|Project|originalProject|' "${samplesheet}"

echo "awk -v project=\"${projectNameGDIO}\" '{if (NR>1){print \$0\",\"project}else{print \$0\",project\"}}' ${samplesheet}"
awk -v project="${projectNameGDIO}" '{if (NR>1){print $0","project}else{print $0",project"}}' "${samplesheet}" > "${samplesheet}.tmp"
pwd
mv "${samplesheet}.tmp" "${samplesheet}"
echo "generating scripts"

generatedScripts="${tmpdir}/generatedscripts/${projectNameGDIO}/"

module purge

mkdir -p "${generatedScripts}"
module load PGx
cp "${EBROOTPGX}/generate_template.sh" "${generatedScripts}/"
cp "${samplesheetFolder}/${projectNameGDIO}.csv" "${generatedScripts}/"

cd "${generatedScripts}/"
bash generate_template.sh

cd "${tmpdir}/projects/${projectNameGDIO}/jobs"

bash submit.sh

