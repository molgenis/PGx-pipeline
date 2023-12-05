//molecular trait data input data
vcf_file_ch = Channel.fromPath(params.vcf_list)
    .ifEmpty { error "Cannot find vcf list file in: ${params.vcf_list}" }
    .splitCsv(header: true, sep: '\t', strip: true)
    .map{row -> [ row.chromosome, file(row.path) ]}

Channel
    .fromPath(params.chromosome_names)
    .ifEmpty { exit 1, "Chromosome names file not found: ${params.chromosome_names}" } 
    .set { chr_names_file_ch }

Channel
    .fromPath( "${params.fna}*" )
    .map { ref -> [file("${params.fna}.fna"), file("${params.fna}.fna.fai")]}
    .set { fasta_ch }

Channel
    .fromPath(params.dbSNP_hg38)
    .map { dbSNP_hg38 -> [file("${dbSNP_hg38}.vcf.gz"), file("${dbSNP_hg38}.vcf.gz.tbi")]}
    .ifEmpty { exit 1, "dbSNP hg38 file: ${params.dbSNP_hg38}" }
    .into{dbSNP_hg38_ch}

rename_chr_input = vcf_file_ch.combine(chr_names_file_ch)   
rename_chr_input.into{rename_chr_input1; rename_chr_input2}

process rename_chromosomes{
    container = 'quay.io/biocontainers/bcftools:1.12--h45bccc9_1'

    input:
    tuple val(chr), file(vcf), file(chromosome_names) from rename_chr_input1

    output:
    tuple val(chr), file("${chr}.renamed.singletons.removed.vcf.gz") into renamed_vcf_ch

    script:
    """
    bcftools annotate --rename-chrs ${params.chromosome_names} ${vcf} -Oz -o ${chr}.renamed.vcf.gz

    # remove singletons and doubletons:
    bcftools view --no-version -e 'INFO/AC<3 | INFO/AN-INFO/AC<3' ${chr}.renamed.vcf.gz -Oz -o ${chr}.renamed.singletons.removed.vcf.gz
    
    """
}

renamed_vcf_ch_to_annotation = renamed_vcf_ch.combine(dbSNP_hg38_ch)

process annotate_with_dbSNP{
    container = 'quay.io/biocontainers/bcftools:1.12--h45bccc9_1'

    publishDir "${params.outdir}/harmonizing_reference", mode: 'copy', pattern: "*.vcf.gz*"

    input:
    tuple val(chr), file(vcf), file(dbSNP_vcf), file(dbSNP_index) from renamed_vcf_ch_to_annotation

    output:
    set val(chr), file("${chr}.annotated.vcf.gz"), file("${chr}.annotated.vcf.gz.tbi") into annotated_vcf_ch
    set val(chr), file("${chr}.annotated.vcf.gz"), file("${chr}.annotated.vcf.gz.tbi") into harmonizing_reference_ch2

    script:
    """
    tabix -p vcf ${vcf}

    bcftools annotate \
    -a ${dbSNP_vcf} \
    -c ID \
    -Oz \
    -o ${chr}.annotated.vcf.gz \
    ${vcf}

    tabix -p vcf ${chr}.annotated.vcf.gz
    """
}

annotated_vcf_ch.into{annotated_vcf_ch_to_phasing; annotated_vcf_ch_to_imputation; harmonizing_reference_ch}


process remove_samples{
    container = 'quay.io/eqtlcatalogue/genimpute:v20.06.1'

    input:
    tuple val(chr), file(vcf), file(index) from harmonizing_reference_ch2

    output:
    file("*_NoSamples.vcf") into VcfNoSamples

    script:
    """
    # Here I construct vcf file without samples, by filtering in only "sample1" (which does not exist in data)
    bcftools view \
    -s sample1 \
    --force-samples \
    ${vcf} > ${vcf.simpleName}_NoSamples.vcf
    """
}

VcfNoSamples2 = VcfNoSamples.collect()

process make_harmonizing_reference{
    container = 'quay.io/eqtlcatalogue/genimpute:v20.06.1'

    publishDir "${params.outdir}/harmonizing_reference", mode: 'copy', pattern: "*_NoSamplesSorted.vcf.gz*"

    input:
    file vcf_no_samples from VcfNoSamples2

    output:
    set file("*_NoSamplesSorted.vcf.gz"), file("*_NoSamplesSorted.vcf.gz.tbi") into CombinedReference

    script:
    """

    sorted_vcfs="chr1_NoSamples.vcf chr2_NoSamples.vcf chr3_NoSamples.vcf chr4_NoSamples.vcf chr5_NoSamples.vcf chr6_NoSamples.vcf chr7_NoSamples.vcf chr8_NoSamples.vcf chr9_NoSamples.vcf \
    chr10_NoSamples.vcf chr11_NoSamples.vcf chr12_NoSamples.vcf chr13_NoSamples.vcf chr14_NoSamples.vcf chr15_NoSamples.vcf chr16_NoSamples.vcf chr17_NoSamples.vcf chr18_NoSamples.vcf chr19_NoSamples.vcf
    chr20_NoSamples.vcf chr21_NoSamples.vcf chr22_NoSamples.vcf"

    bcftools concat -o 30x-GRCh38_NoSamples.vcf \${sorted_vcfs}

    bcftools sort 30x-GRCh38_NoSamples.vcf > 30x-GRCh38_NoSamplesSorted.vcf

    rm 30x-GRCh38_NoSamples.vcf

    bgzip 30x-GRCh38_NoSamplesSorted.vcf
    tabix -p vcf 30x-GRCh38_NoSamplesSorted.vcf.gz
    """
}

process prepare_fasta{
    container = 'quay.io/biocontainers/samtools:0.1.19--h270b39a_9'

    input:
    tuple file(fasta), file(index) from fasta_ch

    output:
    tuple file("${fasta.simpleName}_fixed.fna"), file("${fasta.simpleName}_fixed.fna.fai") into fasta_ch_fixed

    script:
    """
    # remove "chr" from fasta file
    sed 's/>chr/>/g' ${fasta} > ${fasta.simpleName}_fixed.fna
    samtools faidx ${fasta.simpleName}_fixed.fna
    """
}

phasing_input_ch = annotated_vcf_ch_to_phasing.combine(fasta_ch_fixed).unique()

phasing_input_ch.into{phasing_input_ch1; phasing_input_ch2}

process create_phasing_reference{
    container = 'quay.io/biocontainers/bcftools:1.12--h45bccc9_1'

    cpus 1
    memory '20 GB'
    time '24h'

    publishDir "${params.outdir}/phasing_reference", mode: 'copy', pattern: "*.bcf*"

    input:
    tuple val(chr), file(vcf), file(tbi), file(fasta), file(index) from phasing_input_ch1

    output:
    file "*.bcf*" into phasing_output_ch

    script:
    """
    #(bcftools view --no-version -h ${vcf} | \
    #    grep -v "^##contig=<ID=[GNh]" | sed 's/^##contig=<ID=MT/##contig=<ID=chrM/;s/^##contig=<ID=([0-9XY])/##contig=<ID=chr1/'; \
    #    bcftools view --no-version -H -c 2 ${vcf}) | \
    #bcftools norm --no-version -Ou -m -any | \
    #bcftools norm --no-version -Ob -o ${vcf.simpleName}.bcf -d none -f ${fasta} && \
    #bcftools index -f ${vcf.simpleName}.bcf

    (bcftools view --no-version -h ${vcf}; \
    bcftools view --no-version -H -c 2 ${vcf}) | \
    bcftools view --no-version -e 'INFO/AC<3 | INFO/AN-INFO/AC<3' -Ou |
    bcftools norm --no-version -Ou -m -any | \
    bcftools norm --no-version -Ob -o ${vcf.simpleName}.bcf -d none -f ${fasta} && \
    bcftools index -f ${vcf.simpleName}.bcf
    """
}

annotated_vcf_ch_to_imputation.into{annotated_vcf_ch_to_imputation1; annotated_vcf_ch_to_imputation2}

process create_m3vcf{
    container = "quay.io/eqtlcatalogue/minimac3:v2.0.1"

    cpus 1
    memory '30 GB'
    time '42h'

    publishDir "${params.outdir}/imputation_reference", mode: 'copy', pattern: "*.m3vcf.gz"

    input:
    tuple val(chr), file(vcf), file(tbi) from annotated_vcf_ch_to_imputation1

    output:
    tuple val(chr), file("${chr}.m3vcf.gz") into m3vcf_ch

    script:
    """
    minimac3 --refHaps ${vcf} --processReference --prefix ${chr} --rsid
    """
}
