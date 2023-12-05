#!/bin/bash

#SBATCH --time=72:00:00
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=6G
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --job-name="BuildReference"

module load java-1.8.0_40
module load singularity/3.5.3
module load squashfs/4.4

nextflow_path=/gpfs/space/GI/GV/Projects/eQTLGenPhase2/tools/

${nextflow_path}/nextflow run build_reference.nf \
--vcf_list '/gpfs/space/GI/GV/Projects/eQTLGenPhase2/imputation/scripts/genimpute_hg38/build_ref/vcf_list.tsv' \
--chromosome_names '/gpfs/space/GI/GV/Projects/eQTLGenPhase2/imputation/scripts/genimpute_hg38/build_ref/Hg38ToGRCh38_chromosome_map.txt' \
--dbSNP_hg38 '/gpfs/space/GI/GV/Projects/eQTLGenPhase2/imputation/references/hg38/00-All' \
--fna '/gpfs/space/GI/GV/Projects/eQTLGenPhase2/imputation/data/fasta/GCA_000001405.15_GRCh38_no_alt_analysis_set' \
--outdir '/gpfs/space/GI/GV/Projects/eQTLGenPhase2/imputation/data/phasing_and_imputation_references/' \
-with-report MakeReference.html \
-resume \
-profile eqtlgen
