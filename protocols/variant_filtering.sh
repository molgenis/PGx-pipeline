#MOLGENIS walltime=02:00:00 mem=4gb ppn=1

#string plink2Version
#string genotypesPlinkPrefix
#string sampleListPrefix
#string genotypesOxfordPrefix
#string variantsPassedQualityControl
#string project
#string logsDir
#string intermediateDir


set -e
set -u

ml "${plink2Version}"

mkdir -p $(dirname "${genotypesPlinkPrefix}")

plink2 --data "${genotypesOxfordPrefix}" 'ref-first' \
--extract "${variantsPassedQualityControl}" \
--make-bed --out "${genotypesPlinkPrefix}"
