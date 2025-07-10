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


while getopts "p:g:h" opt; 
do
	case "${opt}" in h)showHelp;; p)projectName="${OPTARG}";; g)glaasjes="${OPTARG}";; 
esac 
done

if [[ -z "${projectName:-}" ]]; then showHelp ; echo "projectName is not specified" ; fi ; echo "projectName=${projectName}"
if [[ -z "${glaasjes:-}" ]]; then showHelp ; echo "glaasjes is not specified" ; fi ; echo "glaasjes=${glaasjes}"

tmpdir="/groups/umcg-pgx/tmp07/"
samplesheetFolder="${tmpdir}/Samplesheets/"
rawdata="${tmpdir}/rawdata/hematologie_research_data"


if [[ ! -f "${samplesheetFolder}/${projectName}.csv" ]]
then
  echo "samplesheet should be here: ${samplesheetFolder}/${projectName}.csv "
	exit 1
fi


mkdir -p "${rawdata}/${projectName}"
cd "${rawdata}/${projectName}"

echo "step1: make symlinks for new data"
 
IFS=',' read -r -a array <<< "$glaasjes"
for glaasje in "${glaasjes[@]}"
do
	echo "I am here: ${rawdata}/${projectName}"
	echo "symlinking: /groups/umcg-pgx/tmp07/rawdata/gtc/${glaasje}"
  ln -sf "/groups/umcg-pgx/tmp07/rawdata/gtc/${glaasje}" 
done

projectNameGDIO="${projectName}_plusGDIO"
samplesheet="${samplesheetFolder}/${projectNameGDIO}.csv"

mkdir -p "${rawdata}/${projectNameGDIO}"
cd "${rawdata}/${projectNameGDIO}"
echo "step1: make symlinks for new data + GDIO"

ln -sf ../"${projectName}"/* .
ln -sf ../../GDIO/GTC/* .

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

