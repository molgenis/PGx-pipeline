#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string pythonEnvironment
#string bpmFile
#string gtcDataDir
#string pgxVersion
#string finalReportTxt
#string samplesheet
#string SentrixBarcode_A
#string finalReportsDir

set -e
set -u

module load "${pythonVersion}"
module load "${pgxVersion}"
module list

source "${pythonEnvironment}/bin/activate"

mkdir -p "${finalReportsDir}"

rm -f "${finalReport}"

python "${EBROOTPGX}/scripts/gtc_final_report.py" \
--manifest "${bpmFile}" \
--samplesheet "${samplesheet}" \
--gtc_directory "${gtcDataDir}/${SentrixBarcode_A}/" \
--output_file "${finalReportTxt}"

gzip -f "${finalReportTxt}"
