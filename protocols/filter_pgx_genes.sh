#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=8

#string plinkBfile
#string plinkVersion
#string pgxFilteredPlinkDir

set -e
set -u

module load "${plinkVersion}"
module list

mkdir -p ${pgxFilteredPlinkDir}

plink2 --bfile ${plinkBfile} \
--extract bed1 ${pgxGenesBed} \
--make-bed \
--out ${pgxFilteredPlinkDir}/chr_${chr}