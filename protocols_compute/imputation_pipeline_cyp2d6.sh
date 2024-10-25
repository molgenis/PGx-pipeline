#MOLGENIS walltime=23:59:00 mem=1gb nodes=1 ppn=4

#string javaVersion
#string nextflowVersion
#string pgxVersion
#string samplesheet
#string concatenatedGenotypesOutputDir
#string imputationPipelineReferencePath
#string pgxDataDir
#string gnomadAnnotationFile
#string pgxGenesBed38Flanked
#string imputationFlankSize
#string outputName
#string imputationOutputDir
#string intermediateDir
#string cnvOutDir

set -e
set -u

# Load required modules
module load "${javaVersion}"
module load "${nextflowVersion}"
module load "${pgxVersion}"

grep "CYP2D6" ${pgxGenesBed38Flanked} > "${intermediateDir}/cyp2d6Bed38Flanked.bed"

# Command
cd "${intermediateDir}"
nextflow run "${EBROOTPGX}/pgx-imputation-pipeline/main.nf" \
--samplesheet "${samplesheet}" \
--bfile "${cnvOutDir}.integrated_genotypes_filtered/chr_22" \
--target_ref "${imputationPipelineReferencePath}/hg38/genome_reference/Homo_sapiens.GRCh38.dna.primary_assembly.fa" \
--ref_panel_hg38 "${imputationPipelineReferencePath}/hg38/harmonizing_reference/30x-GRCh38_NoSamplesSorted" \
--eagle_genetic_map "${imputationPipelineReferencePath}/hg38/phasing_reference/genetic_map/genetic_map_hg38_withX.txt.gz" \
--eagle_phasing_reference "${imputationPipelineReferencePath}/hg38/phasing_reference/phasing/" \
--minimac_imputation_reference "${imputationPipelineReferencePath}/hg38/imputation_reference/" \
--chain_file "${EBROOTPGX}/pgx-imputation-pipeline/data/GRCh37_to_GRCh38.chain" \
--annotation_vcf_file "${gnomadAnnotationFile}" \
--range_bed_hg38 "${intermediateDir}/cyp2d6Bed38Flanked.bed" \
--img_location "${pgxDataDir}/pgx-imputation-v2.0.img" \
--imputation_flank_size "${imputationFlankSize}" \
--output_name "${outputName}" \
--outdir "${imputationOutputDir}" \
-profile singularity \
-work-dir "${intermediateDir}/imputation_work_cyp2d6" \
-resume

cd -