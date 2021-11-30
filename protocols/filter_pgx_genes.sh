#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=8

#string chromosomeNumber
#string genotypesPlinkPrefix
#string plinkVersion
#string pgxGenesBed37
#string genotypesPgxFilteredOutputDir

set -e
set -u

module load "${plinkVersion}"
module list

mkdir -p ${genotypesPgxFilteredOutputDir}

plink2 --bfile ${genotypesPlinkPrefix} \
--extract bed1 ${pgxGenesBed37} \
--make-bed \
--out ${genotypesPgxFilteredOutputDir}/chr_${chr}