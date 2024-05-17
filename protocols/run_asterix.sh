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
module load ${htslibVersion}
module load BCFtools

mkdir -p ${cnvOutDir}.target

bcftools query -l ${imputationOutputDir}/target/range_*_CYP2D6.annotated.bar.target.vcf.gz > target_sample_list.txt
awk 'NR==FNR { ids[$1]; next } $1 in ids' target_sample_list.txt ${cnvOutDir}.combined_cnv_status.txt > ${cnvOutDir}.target/cnv_status.txt

mkdir -p ${asterixOutputDir}/star_alleles/
mkdir -p ${asterixOutputDir}/pheno_out/

java -jar /groups/umcg-fg/tmp01/projects/pgx-passport/tools/asterix-0.10-SNAPSHOT.jar \
        -haplo_type_dir         ${imputationOutputDir}/target \
        -cyp2d6_cnv_status      ${cnvOutDir}.target/cnv_status.txt \
        -snp_haplo_table_dir    ${translationTableSnpToHaploDir} \
        -haplo_pheno_table_dir  ${translationTableHaploToCiDir} \
        -star_out               ${asterixOutputDir}/star_alleles/ \
        -pheno_out_dir          ${asterixOutputDir}/pheno_out/ \
        -sample_matrix_out      ${asterixOutputDir}/sample_matrix.csv \
        -hl7_output_file        ${asterixOutputDir}/hl7_llnext_prelim.json \
        -hl7_input_file         ${asterixDefaultJson}
