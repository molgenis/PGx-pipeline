#MOLGENIS walltime=23:59:00 mem=2gb nodes=1 ppn=4

#string outputName
#string javaVersion
#string htslibVersion
#string asterixVersion
#string bcfToolsVersion
#string cnvOutDir
#string imputationOutputDir
#string asterixOutputDir
#string translationTableSnpToHaploDir
#string translationTableHaploToCiDir
#string asterixDefaultJson

set -e
set -u

# Load required modules
module load "${javaVersion}"
module load "${htslibVersion}"
module load "${asterixVersion}"
module load "${bcfToolsVersion}"

mkdir -p "${cnvOutDir}.target"

bcftools query -l "${imputationOutputDir}/target/range_"*"_CYP2C9.annotated.bar.target.vcf.gz" > "${cnvOutDir}.target_sample_list.txt"
head -n 1 "${cnvOutDir}.combined_cnv_status.txt" > "${cnvOutDir}.target/cnv_status.txt"
awk 'NR==FNR { ids[$1]; next } $1 in ids' \
"${cnvOutDir}.target_sample_list.txt" \
"${cnvOutDir}.combined_cnv_status.txt" >> "${cnvOutDir}.target/cnv_status.txt"

mkdir -p "${asterixOutputDir}/star_alleles/"
mkdir -p "${asterixOutputDir}/pheno_out/"

echo "-haplo_type_dir ${imputationOutputDir}/target -cyp2d6_cnv_status ${cnvOutDir}.target/cnv_status.txt -snp_haplo_table_dir ${translationTableSnpToHaploDir} -haplo_pheno_table_dir ${translationTableHaploToCiDir} -star_out ${asterixOutputDir}/star_alleles/ -pheno_out_dir ${asterixOutputDir}/pheno_out/ -sample_matrix_out ${asterixOutputDir}/sample_matrix -hl7_output_file ${asterixOutputDir}/hl7_llnext_prelim.json -hl7_input_file ${asterixDefaultJson}" 
java -jar "${EBROOTASTERIX}/asterix-0.10-SNAPSHOT.jar" \
        -haplo_type_dir         "${imputationOutputDir}/target" \
        -cyp2d6_cnv_status      "${cnvOutDir}.target/cnv_status.txt" \
        -snp_haplo_table_dir    "${translationTableSnpToHaploDir}" \
        -haplo_pheno_table_dir  "${translationTableHaploToCiDir}" \
        -star_out               "${asterixOutputDir}/star_alleles/" \
        -pheno_out_dir          "${asterixOutputDir}/pheno_out/" \
        -sample_matrix_out      "${asterixOutputDir}/sample_matrix.csv" \
        -hl7_output_file        "${asterixOutputDir}/hl7_llnext_prelim.json" \
        -hl7_input_file         "${asterixDefaultJson}"
