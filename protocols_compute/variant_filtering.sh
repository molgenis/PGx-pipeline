#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string plink2Version
#string genotypesPlinkPrefix
#string sampleListPrefix
#string genotypesOxfordPrefix
#string variantsPassedQualityControl


set -e
set -u

ml "${plink2Version}"

mkdir -p $(dirname "${genotypesPlinkPrefix}")
mkdir -p $(dirname "${sampleListPrefix}")

plink2 --data "${genotypesOxfordPrefix}" 'ref-first' \
--extract "${variantsPassedQualityControl}" \
--make-bed --out "${genotypesPlinkPrefix}"

awk 'BEGIN{FS="\t"; OFS=FS}{print $2}' "${genotypesPlinkPrefix}.fam" > "${sampleListPrefix}.samples.txt"
