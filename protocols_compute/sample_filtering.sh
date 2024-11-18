#MOLGENIS walltime=02:00:00 mem=8gb ppn=2

#string pgxVersion
#string plink2Version
#string rVersion

#string sampleListPrefix
#string concatenatedGenotypesOutputDir


set -e
set -u

module load "${pgxVersion}"
module load "${plink2Version}"
module load "${rVersion}"
#export R_LIBS_USER=${rLibsPath}

sampleListPrefixFolder=$(dirname "${sampleListPrefix}")
mkdir -p $(dirname "${sampleListPrefix}")

plink2 --bfile "${concatenatedGenotypesOutputDir}/plink_dataset_to_qc" --out "${sampleListPrefixFolder}/plink2_sample_qc" --missing sample-only --het

Rscript "${EBROOTPGX}/scripts/qc_autosomes.R" \
--sample-missingness "${sampleListPrefixFolder}/plink2_sample_qc.smiss" \
--heterozygosity "${sampleListPrefixFolder}/plink2_sample_qc.het" \
--out-prefix "${sampleListPrefixFolder}/qc_out"

plink2 --bfile "${concatenatedGenotypesOutputDir}/plink_dataset_to_qc" --keep "${sampleListPrefixFolder}/qc_out.samples_passed_qc.txt" \
--make-bed --out "${concatenatedGenotypesOutputDir}/chr_all"

awk 'BEGIN{FS="\t"; OFS=FS}{print $2}' "${concatenatedGenotypesOutputDir}/chr_all.fam" > "${sampleListPrefix}.samples.txt"
