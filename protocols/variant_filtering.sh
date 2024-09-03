set -e
set -u

ml ${plink2Version}
ml ${RPlusVersion}
export R_LIBS_USER=${rLibsPath}

mkdir -p $(dirname ${genotypesPlinkPrefix})
mkdir -p $(dirname ${sampleListPrefix})

plink2 --data ${genotypesOxfordPrefix} 'ref-first' \
--extract ${variantsPassedQualityControl} \
--make-bed --out 'qc_input_plink_dataset' --missing sample-only --het

Rscript ${pipelineRoot}/scripts/qc_autosomes.R \
--sample-missingness qc_input_plink_dataset.smiss \
--heterozygosity qc_input_plink_dataset.het \
--out-prefix qc_out

plink2 --bfile qc_input_plink_dataset --keep qc_out.samples_passed_qc.txt \
--make-bed --out ${genotypesPlinkPrefix}

awk 'BEGIN{FS="\t"; OFS=FS}{print $2}' ${genotypesPlinkPrefix}.fam > ${sampleListPrefix}.samples.txt
