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

count=0
while read line
do
	if [[ "${count}" == 0 ]]
	then
		count=1
	else

		gtcFile=$(echo "${line}" | awk -v sb="${sentrixBarcodeAFieldIndex}" -v sp="${SentrixPositionAFieldIndex}" 'BEGIN {FS=","}{print $sb"_"$sp".gtc"}')
		glaasje=$(echo "${line}" | awk -v sb="${sentrixBarcodeAFieldIndex}" 'BEGIN {FS=","}{print $sb}')
		mkdir -p "${rawdata}/${projectName}/${glaasje}"
		rsync -v "/groups/umcg-pgx/tmp07/rawdata/gtc/${glaasje}/${gtcFile}" "${rawdata}/${projectName}/${glaasje}/"
	fi
		
done<"${samplesheetFolder}/${projectName}.csv"

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

mkdir -p "${generatedScripts}"
module load PGx
cp "${EBROOTPGX}/generate_template.sh" "${generatedScripts}/"
cp "${samplesheetFolder}/${projectNameGDIO}.csv" "${generatedScripts}/"

cd "${generatedScripts}/"
bash generate_template.sh

cd "${tmpdir}/projects/${projectNameGDIO}/jobs"

bash submit.sh

