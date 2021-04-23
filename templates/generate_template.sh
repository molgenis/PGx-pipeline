#!/bin/bash

module load Molgenis-Compute/v17.08.1-Java-1.8.0_74
module load PGx-pipeline/beta
module list

host=$(hostname -s)
environmentParameters="parameters_${host}"

function showHelp() {
	#
	# Display commandline help on STDOUT.
	#
	cat <<EOH
===============================================================================================================
Script to copy (sync) data from a succesfully finished analysis project from tmp to prm storage.
Usage:
	$(basename $0) OPTIONS
Options:
	-h   Show this help.
	-a   sampleType (default=PGX)
	-l   pipeline (default=PGX)
	-p   project
	-g   group (default=basename of ../../../ )
	-f   filePrefix (default=basename of this directory)
	-r   runID (default=run01)
	-t   tmpDirectory (default=basename of ../../ )
	-w   workdir (default=/groups/\${group}/\${tmpDirectory})

===============================================================================================================
EOH
	trap - EXIT
	exit 0
}

while getopts "t:g:w:f:r:l:h:" opt;
do
	case $opt in h)showHelp;; t)tmpDirectory="${OPTARG}";; g)group="${OPTARG}";; w)workDir="${OPTARG}";; f)filePrefix="${OPTARG}";; p)project="${OPTARG}";; r)runID="${OPTARG}";; l)pipeline="${OPTARG}";;
	esac
done

if [[ -z "${tmpDirectory:-}" ]]; then tmpDirectory=$(basename $(cd ../../ && pwd )) ; fi ; echo "tmpDirectory=${tmpDirectory}"
if [[ -z "${group:-}" ]]; then group=$(basename $(cd ../../../ && pwd )) ; fi ; echo "group=${group}"
if [[ -z "${workDir:-}" ]]; then workDir="/groups/${group}/${tmpDirectory}" ; fi ; echo "workDir=${workDir}"
if [[ -z "${filePrefix:-}" ]]; then filePrefix=$(basename $(pwd )) ; fi ; echo "filePrefix=${filePrefix}"
if [[ -z "${runID:-}" ]]; then runID="run01" ; fi ; echo "runID=${runID}"
if [[ -z "${pipeline:-}" ]]; then pipeline="PGX" ; fi ; echo "pipeline=${pipeline}"
genScripts="${workDir}/generatedscripts/${filePrefix}/"
samplesheet="${genScripts}/${filePrefix}.csv" ; mac2unix "${samplesheet}"

host=$(hostname -s)
echo "${host}"

projectDir="${workDir}/projects/${filePrefix}/${runID}/jobs/"

mkdir -p -m 2770 "${workDir}/projects/"
mkdir -p -m 2770 "${workDir}/projects/${filePrefix}/"
mkdir -p -m 2770 "${workDir}/projects/${filePrefix}/${runID}/"
mkdir -p -m 2770 "${workDir}/projects/${filePrefix}/${runID}/jobs/"

#samplesheet="${genScripts}/${filePrefix}.csv" ; mac2unix "${samplesheet}"

perl "${EBROOTPGXMINUSPIPELINE}/scripts/convertParametersGitToMolgenis.pl" "${EBROOTPGXMINUSPIPELINE}/parameters_${host}.csv" > "${genScripts}/parameters_host_converted.csv"
perl "${EBROOTPGXMINUSPIPELINE}/scripts/convertParametersGitToMolgenis.pl" "${EBROOTPGXMINUSPIPELINE}/${pipeline}_parameters.csv" > "${genScripts}/parameters_converted.csv"

sh "${EBROOTMOLGENISMINCOMPUTE}/molgenis_compute.sh" \
-p "${genScripts}/parameters_converted.csv" \
-p "${genScripts}/parameters_host_converted.csv" \
-p "${samplesheet}" \
-w "${EBROOTPGXMINUSPIPELINE}/Prepare_${pipeline}_workflow.csv" \
-weave \
--generate \
-rundir "${genScripts}/scripts" \
--runid "${runID}" \
-o "outputdir=scripts/jobs;\
mainParameters=${genScripts}/parameters_converted.csv;\
samplesheet=${samplesheet};\
Project=${filePrefix};\
pipeline=${pipeline};\
runID=${runID};;"
