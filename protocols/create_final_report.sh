#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string beadArrayVersion
#string pythonEnvironment
#string bpmFile
#string gtcDataDir
#string pgxVersion
#string finalReportTxt
#string samplesheet
#string SentrixBarcode_A
#string finalReportsDir
#string project
#string logsDir
#string intermediateDir

set -e
set -u

module load "${pythonVersion}"
module load "${beadArrayVersion}"
module load "${pgxVersion}"
module list

export PYTHONPATH="${pythonEnvironment}/lib64/python3.10/site-packages/:$PYTHONPATH"

mkdir -p "${finalReportsDir}"

rm -f "${finalReportTxt}"

python "${EBROOTPGX}/scripts/gtc_final_report.py" \
--manifest "${bpmFile}" \
--samplesheet "${samplesheet}" \
--gtc_directory "${gtcDataDir}/${SentrixBarcode_A}/" \
--output_file "${finalReportTxt}"

gzip -f "${finalReportTxt}"
