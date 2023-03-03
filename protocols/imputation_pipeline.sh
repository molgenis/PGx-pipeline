#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=4

#string chromosomeNumber
#string genotypesPlinkPrefix
#string javaVersion
#string nextflowPath
#string pgxGenesBed38
#string pgxGenesBed38Flanked
#string concatenatedGenotypesOutputDir
#string imputationPipelineReferencePath
#string imputationOutputDir
#string outputName

set -e
set -u

# Load required modules
module load ${javaVersion}

# Command
${nextflowPath} run ${pipelineRoot}/pgx-imputation-pipeline/main.nf \
--bfile ${concatenatedGenotypesOutputDir}/chr_all \
--target_ref ${imputationPipelineReferencePath}/hg38/genome_reference/Homo_sapiens.GRCh38.dna.primary_assembly.fa \
--ref_panel_hg38 ${imputationPipelineReferencePath}/hg38/harmonizing_reference/30x-GRCh38_NoSamplesSorted \
--eagle_genetic_map ${imputationPipelineReferencePath}/hg38/phasing_reference/genetic_map/genetic_map_hg38_withX.txt.gz \
--eagle_phasing_reference ${imputationPipelineReferencePath}/hg38/phasing_reference/phasing/ \
--minimac_imputation_reference ${imputationPipelineReferencePath}/hg38/imputation_reference/ \
--chain_file ${pipelineRoot}/pgx-imputation-pipeline/data/GRCh37_to_GRCh38.chain \
--annotation_vcf_file ${gnomadAnnotationFile} \
--indel_mapping_file ${indelMappingFile} \
--range_bed_hg38 ${pgxGenesBed38Flanked} \
--imputation_flank_size ${imputationFlankSize} \
--output_name ${outputName} \
--outdir ${imputationOutputDir} \
-profile singularity \
-resume
