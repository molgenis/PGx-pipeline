# eQTLGen/genimpute workflow
Genotype imputation and quality control workflow used by the eQTLGen phase II. This is modified from the genotype imputation workflow developed by eQTL Catalogue team (https://github.com/eQTL-Catalogue/genimpute).


Performs the following main steps:

**Pre-imputation QC:**
- Convert the genotypes to the VCF format with [PLINK](https://www.cog-genomics.org/plink/1.9/).
- Convert raw genotypes to GRCh38 coordinates with CrossMap.py v0.4.1
- Align raw genotypes to the reference panel with [Genotype Harmonizer](https://github.com/molgenis/systemsgenetics/wiki/Genotype-Harmonizer).
- Exclude variants with Hardy-Weinberg p-value < 1e-6, missingness > 0.05 and minor allele frequency < 0.01 with [bcftools](https://samtools.github.io/bcftools/)
- Calculate individual-level missingness using [vcftools](https://vcftools.github.io/perl_module.html).

**Imputation:**
- Genotype pre-phasing with Eagle 2.4.1 
- Genotype imputation with Minimac4

## Usage information

### Input files

Pipeline expects as an input the folder with unimputed plink bgen files.

### Help files

Pipeline needs several reference files to do data processing, QC, and imputation:

- hg19 .vcf.gz reference for fixing the alleles and harmonizing the data before CrossMap to hg38
- hg38 .vcf.gz reference for fixing the alleles and harmonizing the data after CrossMap to hg38
- hg19 reference genome .fasta file
- hg38 reference genome .fasta file
- dbSNP hg19 vcf
- dbSNP hg38 vcf
- Phasing reference (hg38)
- Genetic map for phasing
- Imputation reference
- CrossMap chain file (comes with the pipeline)

These are organised to the on folder and all you need to do is to download the zipped file, unzip and change the path in the relevant script template.

### Running the imputation command

Replace the required paths in the script template.

´´´{bash}
#!/bin/bash

#SBATCH --time=72:00:00
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=6G
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-user=[your e-mail address to send notification]
#SBATCH --job-name="ImputeGenotypes"

module load java-1.8.0_40
module load singularity/3.5.3
module load squashfs/4.4

# Define paths
nextflow_path=[full path to your Nextflow executable]
reference_path=[full path to your folder with reference files]

input_path=[full path to your input genotype folder]
output_name=[name of the output files]
output_path=[name of the output path]

${nextflow_path}/nextflow run main.nf \
--bfile ${input_path} \
--source_ref ${reference_path}/hg19/ref_genome_QC/Homo_sapiens.GRCh37.dna.primary_assembly.fa \
--target_ref ${reference_path}/hg38/ref_genome_QC/Homo_sapiens_assembly38.fasta \
--ref_panel_hg19 ${reference_path}/hg19/ref_panel_QC/1000G_GRCh37_variant_information \
--ref_panel_hg38 ${reference_path}/hg38/ref_panel_QC/30x-GRCh38_NoSamplesSorted \
--dbSNP_hg19 ${reference_path}/hg19/SNP_annotation/00-All \
--dbSNP_hg38 ${reference_path}/hg38/SNP_annotation/00-All \
--eagle_genetic_map ${reference_path}/hg38/phasing/genetic_map_hg38_withX.txt.gz \
--eagle_phasing_reference ${reference_path}/hg38/phasing/ \
--minimac_imputation_reference ${reference_path}/hg38/imputation/ \
--output_name ${output_name} \
--outdir ${output_path}  \
-profile eqtlgen \
-resume

´´´

## Contributors

Original pipeline was developed:

* Kaur Alasoo
* Liina Anette Pärtel
* Mark-Erik Kodar

Original pipeline was adjusted to work with 1000G p3 30X WGS reference panel:

* Ralf Tambets

Elements of those original pipelines were adjusted to work with 1000G 30X WGS reference panel and accustomised for eQTLGen consortium analyses:

* Urmo Võsa

Processes are adapted to work on selected bits of the genome:

* Robert Warmerdam