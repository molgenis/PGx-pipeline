#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=8

#string pharmvarTable
#string reference
#string plink2Version
#string pgxGenesBed37Flanked
#string genotypesPgxFilteredOutputDir

set -e
set -u

module load "${RPlusVersion}"
module list

mkdir -p ${pharmvarProcessedHaplotypeDir}

# Pipe rsids from reference to mapping file
zcat ${imputationPipelineReferencePath}/hg38/harmonizing_reference/30x-GRCh38_NoSamplesSorted.vcf.gz \
| grep -F -f ${missingIndelFile} > reference_indels.txt

for pharmvarFilename in ${pharmvarHaplotypeDir}/*.haplotypes.tsv; do
  # Start R script to normalise indels
  Rscript ${pipelineRoot}/scripts/normalize_pharmvar_indels.R \
  --reference-indels reference_indels.txt \
  --pharmvar-table ${pharmvarHaplotypeDir}/${pharmvarFilename} \
  --out ${pharmvarProcessedHaplotypeDir}/
done