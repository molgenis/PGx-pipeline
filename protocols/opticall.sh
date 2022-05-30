#MOLGENIS walltime=23:59:00 mem=8gb ppn=2

#string gapVersion
#string Project
#string logsDir
#string intermediateDir
#string optiCallDir
#string opticallExecutable
#string chr

set -e
set -u

module load opticall/0.8.1-foss-2018b
module list

tmpOptiCallDir="tmp"

mkdir ${tmpOptiCallDir}

${EBROOTOPTICALL}/opticall \
-in ${optiCallDir}/${chr} \
-out ${tmpOptiCallDir}/${chr}


echo "mv ${tmpOptiCallDir}/${chr}.probs ${optiCallDir}/"
echo "mv ${tmpOptiCallDir}/${chr}.calls ${optiCallDir}/"
mv "${tmpOptiCallDir}/${chr}.probs" "${optiCallDir}/"
mv "${tmpOptiCallDir}/${chr}.calls" "${optiCallDir}/"
