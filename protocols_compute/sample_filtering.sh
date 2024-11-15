#MOLGENIS walltime=02:00:00 mem=8gb ppn=2

#string pgxVersion
#string plink2Version
#string RPlusVersion

#string sampleListPrefix
#string concatenatedGenotypesOutputDir


set -e
set -u

module load "${pgxVersion}"
module load "${plink2Version}"
module load "${RPlusVersion}"
#export R_LIBS_USER=${rLibsPath}

mkdir -p $(dirname "${sampleListPrefix}")

plink2 --bfile "${concatenatedGenotypesOutputDir}/plink_dataset_to_qc" --out 'plink2_sample_qc' --missing sample-only --het

Rscript "${EBROOTPGX}/scripts/qc_autosomes.R" \
--sample-missingness 'plink2_sample_qc.smiss' \
--heterozygosity 'plink2_sample_qc.het' \
--out-prefix 'qc_out'

plink2 --bfile "${concatenatedGenotypesOutputDir}/plink_dataset_to_qc" --keep "qc_out.samples_passed_qc.txt" \
--make-bed --out "${concatenatedGenotypesOutputDir}/chr_all"

awk 'BEGIN{FS="\t"; OFS=FS}{print $2}' "${concatenatedGenotypesOutputDir}/chr_all.fam" > "${sampleListPrefix}.samples.txt"
