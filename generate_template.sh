#!/bin/bash
set -eu
if module list | grep -o -P 'PGx(.+)' 
then
	echo "PGx pipeline loaded, proceding"
else
	echo "No PGx Pipeline loaded, exiting"
	exit 1
fi

module list

host=$(hostname -s)
environmentParameters="parameters_${host}"

function showHelp() {
	#
	# Display commandline help on STDOUT.
	#
	cat <<EOH
===============================================================================================================
Usage:
	$(basename $0) OPTIONS
Options:
	-h   Show this help.
	-t   tmpDirectory (default=basename of ../../../ )
	-g   group (default=basename of ../../../../ && pwd )
	-w   groupDir (default=basename of ../../../../ && pwd )
	-f   filePrefix (default=basename of this directory)
	-r   runID (default=run01)

===============================================================================================================
EOH
	trap - EXIT
	exit 0
}

while getopts "t:g:w:p:h" opt;
do
	case $opt in
		h)
			showHelp;;
		t)
			tmpDirectory="${OPTARG}";;
		g)
			group="${OPTARG}";;
		w)
			groupDir="${OPTARG}";;
		p)
			project="${OPTARG}";;
	esac
done

if [[ -z "${tmpDirectory:-}" ]]; then tmpDirectory=$(basename $(cd ../../ && pwd )) ; fi ; echo "tmpDirectory=${tmpDirectory}"
if [[ -z "${group:-}" ]]; then group=$(basename $(cd ../../../ && pwd )) ; fi ; echo "group=${group}"
if [[ -z "${groupDir:-}" ]]; then groupDir="/groups/${group}/" ; fi ; echo "groupDir=${groupDir}"
if [[ -z "${project:-}" ]]; then project=$(basename $(pwd )) ; fi ; echo "project=${project}"

genScripts="${groupDir}/${tmpDirectory}/generatedscripts/${project}/"
samplesheet="${genScripts}/${project}.csv"

mkdir -p "${groupDir}/${tmpDirectory}/projects/${project}/jobs"
mkdir -p "${groupDir}/${tmpDirectory}/tmp/${project}/"

### Converting parameters to compute parameters
echo "tmpName,${tmpDirectory}" > "${genScripts}/tmpdir_parameters.csv"
perl "${EBROOTPGX}/scripts/convertParametersGitToMolgenis.pl" "${genScripts}/tmpdir_parameters.csv" > "${genScripts}/parameters_tmpdir_converted.csv"
perl "${EBROOTPGX}/scripts/convertParametersGitToMolgenis.pl" "${EBROOTPGX}/parameters.csv" > "${genScripts}/parameters_converted.csv"
perl "${EBROOTPGX}/scripts/convertParametersGitToMolgenis.pl" "${EBROOTPGX}/${environmentParameters}.csv" > "${genScripts}/parameters_environment_converted.csv"

pgxversion=$(module list | grep -o -P 'PGx(.+)');

module load Molgenis-Compute

bash "${EBROOTMOLGENISMINCOMPUTE}/molgenis_compute.sh" \
-p "parameters_converted.csv" \
-p "${genScripts}/parameters_environment_converted.csv" \
-p "${genScripts}/parameters_tmpdir_converted.csv" \
-p "${genScripts}/${project}.csv" \
-p "${EBROOTPGX}/chromosome_list.csv" \
-w "${EBROOTPGX}/workflow_pgx.csv" \
-rundir "${groupDir}/${tmpDirectory}/projects/${project}/jobs/" \
-b slurm \
-runid "run01" \
--generate \
-o "groupname=${group};\
pgxVersion=${pgxversion};\
samplesheet=${samplesheet};\
groupDir=${groupDir}" \
-g \
-weave

cd "${groupDir}/${tmpDirectory}/projects/${project}/"
## additional removing duplicate values in scripts 
ml Perl
perl "${EBROOTPGX}/scripts/RemoveDuplicatesCompute.pl" 'jobs/'*.sh
rm -f 'jobs/'*bak*

cd -

