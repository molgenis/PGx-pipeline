#MOLGENIS walltime=02:00:00 mem=4gb
#list SentrixBarcode_A,SentrixPosition_A
#string projectRawTmpDataDir
#string intermediateDir
#string resultDir
#string computeVersion
#string Project
#string projectJobsDir
#string projectRawTmpDataDir
#string genScripts
#string pgxVersion
#string pipeline
#string runID
#string logsDir
#string perlVersion
#string projectLogsDir
#string arrayFinalReport
#string PlinkDir

umask 0007

module load ${computeVersion}
module load ${pgxVersion}
module list


#Create ProjectDirs
mkdir -p -m 2770 "${intermediateDir}"
mkdir -p -m 2770 "${resultDir}"
mkdir -p -m 2770 "${projectJobsDir}"
mkdir -p -m 2770 "${projectRawTmpDataDir}"
mkdir -p -m 2770 "${projectLogsDir}"
mkdir -p -m 2770 "${arrayFinalReport}"
mkdir -p -m 2770 "${PlinkDir}"

#Create Symlinks

rocketPoint=$(pwd)
host=$(hostname -s)

cd "${projectRawTmpDataDir}"

max_index=${#SentrixPosition_A[@]}-1

if [ ${pipeline} == 'PGX' ]
then
for ((samplenumber = 0; samplenumber <= max_index; samplenumber++))
do
	ln -sf "../../../../../rawdata/array/GTC/${SentrixBarcode_A[samplenumber]}/${SentrixBarcode_A[samplenumber]}_${SentrixPosition_A[samplenumber]}.gtc" \
	"${projectRawTmpDataDir}/${SentrixBarcode_A[samplenumber]}_${SentrixPosition_A[samplenumber]}.gtc"

	ln -sf "../../../../../rawdata/array/GTC/${SentrixBarcode_A[samplenumber]}/${SentrixBarcode_A[samplenumber]}_${SentrixPosition_A[samplenumber]}.md5" \
	"${projectRawTmpDataDir}/${SentrixBarcode_A[samplenumber]}_${SentrixPosition_A[samplenumber]}.md5"
done
else

for ((samplenumber = 0; samplenumber <= max_index; samplenumber++))
do
	mkdir -p ${SentrixBarcode_A[samplenumber]}
	ln -sf "../../../../../../rawdata/array/GTC/${SentrixBarcode_A[samplenumber]}/${SentrixBarcode_A[samplenumber]}_${SentrixPosition_A[samplenumber]}.gtc" \
        "${projectRawTmpDataDir}/${SentrixBarcode_A[samplenumber]}/${SentrixBarcode_A[samplenumber]}_${SentrixPosition_A[samplenumber]}.gtc"

        ln -sf "../../../../../../rawdata/array/GTC/${SentrixBarcode_A[samplenumber]}/${SentrixBarcode_A[samplenumber]}_${SentrixPosition_A[samplenumber]}.md5" \
        "${projectRawTmpDataDir}/${SentrixBarcode_A[samplenumber]}/${SentrixBarcode_A[samplenumber]}_${SentrixPosition_A[samplenumber]}.md5"
done

fi

#Copying samplesheet to project jobs,results folder

cp "${genScripts}/${Project}.csv" "${projectJobsDir}/${Project}.csv"
cp "${genScripts}/${Project}.csv" "${resultDir}/${Project}.csv"

#
# Execute MOLGENIS/compute to create job scripts to analyse this project.
#

cd "${rocketPoint}"

perl "${EBROOTPGXMINUSPIPELINE}/scripts/convertParametersGitToMolgenis.pl" "${EBROOTPGXMINUSPIPELINE}/parameters_${host}.csv" > "${rocketPoint}/parameters_host_converted.csv"
perl "${EBROOTPGXMINUSPIPELINE}/scripts/convertParametersGitToMolgenis.pl" "${EBROOTPGXMINUSPIPELINE}/${pipeline}_parameters.csv" > "${rocketPoint}/parameters_converted.csv"

sh "${EBROOTMOLGENISMINCOMPUTE}/molgenis_compute.sh" \
-p "${genScripts}/parameters_converted.csv" \
-p "${genScripts}/parameters_host_converted.csv" \
-p "${genScripts}/${Project}.csv" \
-p "${EBROOTPGXMINUSPIPELINE}/chromosomes.csv" \
-rundir "${projectJobsDir}" \
-w "${EBROOTPGXMINUSPIPELINE}/${pipeline}_workflow.csv" \
--header "${EBROOTPGXMINUSPIPELINE}/templates/slurm/header.ftl" \
--submit "${EBROOTPGXMINUSPIPELINE}/templates/slurm/submit.ftl" \
--footer "${EBROOTPGXMINUSPIPELINE}/templates/slurm/footer.ftl" \
-o "runID=${runID}" \
-b slurm \
-g \
-weave \
-runid "${runID}"

 sampleSize=$(cat "${genScripts}/${Project}.csv" |  wc -l)

if [ ${pipeline} == 'research' ] && [ $sampleSize -gt 1000 ]
then
	echo "Samplesize is ${sampleSize}"
	ml "${perlVersion}"
	perl ${EBROOTPGXMINUSPIPELINE}/scripts/RemoveDuplicatesCompute.pl "${projectJobsDir}/"*"_mergeFinalReports_0.sh"
 fi
