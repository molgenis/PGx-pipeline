def helpMessage() {
    log.info"""
    =======================================================
                                              ,--./,-.
              ___     __   __   __   ___     /,-._.--~\'
        |\\ | |__  __ /  ` /  \\ |__) |__         }  {
        | \\| |       \\__, \\__/ |  \\ |___     \\`-._,-`-,
                                              `._,._,\'
     eqtlgenimpute v${workflow.manifest.version}
    =======================================================
    Usage:
    The typical command for running the pipeline is as follows:
    nextflow run main.nf -profile eqtlgen -resume\
        --bfile CohortName_hg37_genotyped\
        --output_name CohortName_hg38_imputed\
        --outdir CohortName

    Mandatory arguments:
      --bfile                       Path to the input unimputed plink files (without extensions bed/bim/fam, has to be in hg19).
      --output_name                 Prefix for the output files.
      --outdir                      The output directory where the results will be saved.
      --target_ref                  Reference genome fasta file for the target genome assembly (e.g. GRCh38).
      --ref_panel_hg38              Reference panel used for strand fixing and GenotypeHarmonizer after LiftOver (GRCh38).
      --eagle_genetic_map           Eagle genetic map file.
      --eagle_phasing_reference     Phasing reference panel for Eagle (1000 Genomes 30x WGS high coverage).
      --minimac_imputation_reference Imputation reference panel for Minimac4 in M3VCF format (1000 Genomes 30x WGS high coverage).

    Optional arguments:
      --chain_file                  Chain file to translate genomic cooridnates from the source assembly to target assembly (hg19 --> hg38). hg19-->hg38 works by default.

    Other options:
      --email                       Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits.
      -name                         Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

    """.stripIndent()
}

// Show help message
if (params.help){
    helpMessage()
    exit 0
}

// Has the run name been specified by the user?
//  this has the bonus effect of catching both -name and --name
custom_runName = params.name
if( !(workflow.runName ==~ /[a-z]+_[a-z]+/) ){
  custom_runName = workflow.runName
}


// Define input channels
Channel
    .from(params.bfile)
    .map { study -> [file("${study}.bed"), file("${study}.bim"), file("${study}.fam")]}
    .set { bfile_ch }

Channel
    .fromPath(params.ref_panel_hg38)
    .map { ref -> [file("${ref}.vcf.gz"), file("${ref}.vcf.gz.tbi")] }
    .into { ref_panel_harmonise_genotypes_hg38; ref_panel_fixref_genotypes_hg38 }

Channel
    .fromPath( "${params.eagle_phasing_reference}*" )
    .ifEmpty { exit 1, "Eagle phasing reference not found: ${params.eagle_phasing_reference}" }
    .set { phasing_ref_ch }

Channel
    .fromPath( "${params.minimac_imputation_reference}*" )
    .ifEmpty { exit 1, "Minimac4 imputation reference not found: ${params.minimac_imputation_reference}" }
    .set { imputation_ref_ch }

Channel
    .fromPath(params.eagle_genetic_map)
    .ifEmpty { exit 1, "Eagle genetic map file not found: ${params.eagle_genetic_map}" } 
    .set { genetic_map_ch }

Channel
    .fromPath(params.chain_file)
    .ifEmpty { exit 1, "CrossMap.py chain file not found: ${params.chain_file}" } 
    .set { chain_file_ch }

Channel
    .fromPath(params.indel_mapping_file)
    .ifEmpty { exit 1, "indel mapping file not found: ${params.indel_mapping_file}" }
    .set { indel_mapping_file_ch }

Channel
    .fromPath(params.target_ref)
    .ifEmpty { exit 1, "CrossMap.py target reference genome file: ${params.target_ref}" } 
    .into { target_ref_ch; target_ref_ch2 }

Channel
    .fromPath(params.annotation_vcf_file)
    .set { annotation_vcf_ch }

Channel
    .fromPath(params.range_bed_hg38)
    .splitCsv(header: ['chrom', 'start', 'end', 'name'], sep: "\t")
    .map { bed -> tuple(bed.chrom, bed.start, bed.end, bed.name) }
    .view()
    .tap { bed_ranges }
    .map { bed -> bed[0] }
    .unique()
    .view()
    .set { chromosomes_of_interest }

// Header log info
log.info """=======================================================
                                          ,--./,-.
          ___     __   __   __   ___     /,-._.--~\'
    |\\ | |__  __ /  ` /  \\ |__) |__         }  {
    | \\| |       \\__, \\__/ |  \\ |___     \\`-._,-`-,
                                          `._,._,\'
eqtlgenimpute v${workflow.manifest.version}"
======================================================="""
def summary = [:]
summary['Pipeline Name']            = 'pgxgenimpute'
summary['Pipeline Version']         = workflow.manifest.version
summary['Run Name']                 = custom_runName ?: workflow.runName
summary['PLINK bfile']              = params.bfile
summary['Harmonise genotypes']      = params.harmonise_genotypes
summary['Reference genome hg38']         = params.ref_genome
summary['Harmonisation ref panel hg38']  = params.ref_panel_hg38
summary['CrossMap reference genome hg38'] = params.target_ref
summary['CrossMap chain file']      = params.chain_file
summary['Eagle genetic map']        = params.eagle_genetic_map
summary['Eagle reference panel']    = params.eagle_phasing_reference
summary['Minimac4 reference panel'] = params.minimac_imputation_reference
summary['Range bed file']           = params.range_bed_hg38
summary['Imputation flank size']    = params.imputation_flank_size
summary['Max Memory']               = params.max_memory
summary['Max CPUs']                 = params.max_cpus
summary['Max Time']                 = params.max_time
summary['Output name']              = params.output_name
summary['Output dir']               = params.outdir
summary['Working dir']              = workflow.workDir
summary['Container Engine']         = workflow.containerEngine
if(workflow.containerEngine) summary['Container'] = workflow.container
summary['Current home']             = "$HOME"
summary['Current user']             = "$USER"
summary['Current path']             = "$PWD"
summary['Working dir']              = workflow.workDir
summary['Script dir']               = workflow.projectDir
summary['Config Profile']           = workflow.profile
if(workflow.profile == 'awsbatch'){
   summary['AWS Region']            = params.awsregion
   summary['AWS Queue']             = params.awsqueue
}
if(params.email) summary['E-mail Address'] = params.email
log.info summary.collect { k,v -> "${k.padRight(21)}: $v" }.join("\n")
log.info "========================================="

process crossmap{

    input:
    set file(study_name_bed), file(study_name_bim), file(study_name_fam) from bfile_ch
    file chain_file from chain_file_ch.collect()
 
    output:
    tuple file("crossmapped_plink.bed"), file("crossmapped_plink.bim"), file("crossmapped_plink.fam") into crossmapped

    shell: 
    //Converts BIM to BED and converts the BED file via CrossMap. 
    //Finds excluded SNPs and removes them from the original plink file. 
    //Then replaces the BIM with CrossMap's output.
    """
    awk '{print \$1,\$4,\$4+1,\$2,\$5,\$6,\$2 "___" \$5 "___" \$6}' ${study_name_bed.simpleName}.bim > crossmap_input.bed
    CrossMap.py bed ${chain_file} crossmap_input.bed crossmap_output.bed
    awk '{print \$7}' crossmap_input.bed | sort > input_ids.txt
    awk '{print \$7}' crossmap_output.bed | sort > output_ids.txt
    comm -23 input_ids.txt output_ids.txt | awk '{split(\$0,a,"___"); print a[1]}' > excluded_ids.txt
    plink2 --bfile ${study_name_bed.simpleName} --exclude excluded_ids.txt --make-bed --output-chr MT --out crossmapped_plink
    awk -F'\t' 'BEGIN {OFS=FS} {print \$1,\$4,0,\$2,\$5,\$6}' crossmap_output.bed > crossmapped_plink.bim
    """
}

process sort_bed{
    input:
    tuple file(study_name_bed), file(study_name_bim), file(study_name_fam) from crossmapped

    output:
    tuple file("sorted.bed"), file("sorted.bim"), file("sorted.fam") into sorted_genotypes_hg38_ch

    script:
    """
    plink2 --bfile ${study_name_bed.simpleName} --make-bed --output-chr MT --out sorted
    """
}

process plink_fix_indels{
    input:
    set file(study_name_bed), file(study_name_bim), file(study_name_fam) from sorted_genotypes_hg38_ch
    file indel_mapping_file from indel_mapping_file_ch

    output:
    tuple file("mapped_indels.bed"), file("mapped_indels.bim"), file("mapped_indels.fam") into indel_fix_genotypes_hg38_ch

    script:
    """
    plink2 --bfile ${study_name_bed.simpleName} \
    --update-alleles ${indel_mapping_file} \
    --update-map ${indel_mapping_file} 6 \
    --out mapped_indels --make-bed
    """
}

process plink_to_vcf{
    input:
    set file(study_name_bed), file(study_name_bim), file(study_name_fam) from indel_fix_genotypes_hg38_ch

    output:
    file "sorted_hg38.vcf" into sorted_hg38_vcf_ch

    script:
    """
    plink2 --bfile ${study_name_bed.simpleName} --export vcf-4.2 id-paste=iid --chr 1-22 --out sorted_hg38
    """
}

process vcf_fixref_hg38{
    input:
    file input_vcf from sorted_hg38_vcf_ch
    file fasta from target_ref_ch2.collect()
    set file(vcf_file), file(vcf_file_index) from ref_panel_fixref_genotypes_hg38

    output:
    file "fixref_hg38.vcf.gz" into fixed_to_filter

    script:
    """
    bcftools sort ${input_vcf} --output-type z -o ${input_vcf}.gz
    bcftools index ${input_vcf}.gz

    bcftools +fixref ${input_vcf}.gz -- -f ${fasta} -i ${vcf_file} | \
    bcftools norm --check-ref x -f ${fasta} | \
    bcftools sort -Oz -o fixref_hg38.vcf.gz
    """
}

process filter_preimpute_vcf{
    publishDir "${params.outdir}/preimpute/", mode: 'copy',
        saveAs: {filename -> if (filename == "filtered.vcf.gz") "${params.output_name}_preimpute.vcf.gz" else null }

    input:
    file input_vcf from fixed_to_filter

    output:
    set file("filtered.vcf.gz"), file("filtered.vcf.gz.csi") into split_vcf_input, missingness_input

    script:
    """
    #Index
    bcftools sort ${input_vcf} --output-type z -o ${input_vcf}.gz
    bcftools index ${input_vcf}.gz

    #Add tags
    bcftools +fill-tags ${input_vcf} -Oz -o tagged.vcf.gz

    #Filter rare and non-HWE variants and those with abnormal alleles and duplicates
    bcftools filter -i 'INFO/HWE > 1e-6 & F_MISSING < 0.05' tagged.vcf.gz |\
     bcftools norm -d all |\
     bcftools norm -m+any |\
     bcftools view -m2 -M2 -Oz -o filtered.vcf.gz

     #Index the output file
     bcftools index filtered.vcf.gz
    """
}

process calculate_missingness{
    publishDir "${params.outdir}/preimpute/", mode: 'copy',
        saveAs: {filename -> if (filename == "genotypes.imiss") "${params.output_name}.imiss" else null }
    
    input:
    set file(input_vcf), file(input_vcf_index) from missingness_input 

    output:
    file "genotypes.imiss" into missing_individuals

    script:
    """
    vcftools --gzvcf ${input_vcf} --missing-indv --out genotypes
    """
}

process split_by_chr{
    publishDir "${params.outdir}/preimpute/split_chr", mode: 'copy',
        saveAs: {filename -> if (filename.indexOf(".vcf.gz") > 0) filename else null }

    input:
    tuple file(input_vcf), file(input_vcf_index) from split_vcf_input
    each chr from chromosomes_of_interest

    output:
    tuple val(chr), file("chr_${chr}.vcf.gz") into individual_chromosomes

    script:
    """
    bcftools view -r ${chr} ${input_vcf} -Oz -o chr_${chr}.vcf.gz
    """
}

process eagle_prephasing{
    input:
    tuple chromosome, file(vcf) from individual_chromosomes
    file genetic_map from genetic_map_ch.collect()
    file phasing_reference from phasing_ref_ch.collect()

    output:
    tuple chromosome, file("chr${chromosome}.phased.vcf.gz") into phased_vcf_cf

    script:
    """
    bcftools index ${vcf}
    eagle --vcfTarget=${vcf} \
    --vcfRef=chr${chromosome}.bcf \
    --geneticMapFile=${genetic_map} \
    --chrom=${chromosome} \
    --outPrefix=chr${chromosome}.phased \
    --numThreads=${task.cpus}
    """
}

process minimac_imputation{
    publishDir "${params.outdir}/postimpute/", mode: 'copy', pattern: "*.dose.vcf.gz"

    input:
    tuple chromosome, file(vcf), chrom, start, end, name from phased_vcf_cf.cross(bed_ranges).map { crossbed -> crossbed.flatten() }
    file imputation_reference from imputation_ref_ch.collect()
    val flank_size from params.imputation_flank_size

    output:
    tuple chromosome, start, end, name, file("range_${chromosome}_${start}-${end}_${name}.dose.vcf.gz") into imputed_vcf_cf

    script:
    // Start minimac
    """
    tabix ${vcf}

    minimac4 --refHaps chr${chromosome}.m3vcf.gz \
    --haps ${vcf} \
    --chr ${chromosome} \
    --start ${start} \
    --end ${end} \
    --window ${flank_size} \
    --prefix imputed \
    --format GT,GP,HDS \
    --noPhoneHome

    tabix imputed.dose.vcf.gz

    bcftools concat ${vcf} imputed.dose.vcf.gz \
    --regions ${chromosome}:${start}-${end} \
    --remove-duplicates --allow-overlaps \
    --output range_${chromosome}_${start}-${end}_${name}.dose.vcf.gz \
    --output-type z
    """
}

process index_imputation {
    publishDir "${params.outdir}/postimpute/", mode: 'copy', pattern: "*.dose.vcf.gz.tbi"

    input:
    tuple chromosome, start, end, name, file(vcf) from imputed_vcf_cf

    output:
    tuple chromosome, start, end, name, file(vcf), file("*.tbi") into imputed_vcf_tbi_cf

    script:
    """
    tabix ${vcf}
    """
}

process annotate_imputation {
    publishDir "${params.outdir}/annotated/", mode: 'copy', pattern: "*.annotated.vcf.gz"
    publishDir "${params.outdir}/annotated/", mode: 'copy', pattern: "*.annotated.vcf.gz.tbi"

    input:
    tuple chromosome, start, end, name, file(vcf), file(index) from imputed_vcf_tbi_cf
    file annotation_vcf from annotation_vcf_ch.collect()

    output:
    tuple chromosome, start, end, name, file("*.vcf.gz"), file("*.vcf.gz.tbi") into annotated_vcf_tbi_cf

    script:
    """
    tabix ${annotation_vcf}

    bcftools annotate ${vcf} -x "INFO/AF" -O z -o removed_af_info.vcf.gz
    tabix removed_af_info.vcf.gz
    
    bcftools annotate removed_af_info.vcf.gz \
    --annotations ${annotation_vcf} \
    --columns "INFO,ID" \
    --output range_${chromosome}_${start}-${end}_${name}.annotated.vcf.gz \
    --output-type 'z'

    tabix range_${chromosome}_${start}-${end}_${name}.annotated.vcf.gz
    """
}
