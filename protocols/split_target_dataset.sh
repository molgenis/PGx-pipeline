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

${imputationOutputDir}/annotated ${splitTargetDataset}/imputed \
        -cyp2d6_cnv_status      ${splitTargetDataset}/cnv/cnv_status.txt \
        -snp_haplo_table_dir    ${translationTableSnpToHaploDir} \
        -haplo_pheno_table_dir  ${translationTableHaploToCiDir} \
        -star_out               ${asterixOutputDir}/star_alleles/ \
        -pheno_out_dir          ${asterixOutputDir}/pheno_out/ \
        -sample_matrix_out      ${asterixOutputDir}/sample_matrix \
        -hl7_output_file        ${asterixOutputDir}/hl7_llnext_prelim.json \
        -hl7_input_file         ${asterixDefaultJson}

for p in ${imputationOutputDir}/annotated
do
    f=$(basename -- "$p")
    range=${f%.annotated.bar.vcf.gz}
    gene=${range##*_}
    rsids="included_rsids/${gene}.txt"
    if [ ! -f $rsids ]
    then
        echo "$rsids does not exist"
        continue
    fi
    echo "Processing $gene file..."
    bcftools query -l $p > $vcf_out/oldnames/${gene}_oldnames.txt
    python change_llnext_IDs.py $vcf_out $gene

    bcftools reheader -s $vcf_out/newnames/${gene}_newnames.txt -o $vcf_out/renamed_vcf/$f $p
    bcftools index --tbi $vcf_out/renamed_vcf/$f

    bcftools view --samples-file $vcf_out/cohort_sample_lists/${gene}_val.txt --include ID==@$rsids $vcf_out/renamed_vcf/$f -o $vcf_out/split_vcf/val/no_AC/$f
    bcftools +fill-tags $vcf_out/split_vcf/val/no_AC/$f -o $vcf_out/split_vcf/val/$f -- -t AF
    bcftools index --tbi $vcf_out/split_vcf/val/$f
    bcftools view $vcf_out/split_vcf/val/$f > $vcf_out/split_vcf/val/textfiles/${gene}.txt
    python extract_genotypes.py $vcf_out val $gene

    bcftools view --samples-file $vcf_out/cohort_sample_lists/${gene}_gdio.txt --include ID==@$rsids $vcf_out/renamed_vcf/$f -o $vcf_out/split_vcf/gdio/no_AC/$f
    bcftools +fill-tags $vcf_out/split_vcf/gdio/no_AC/$f -o $vcf_out/split_vcf/gdio/$f -- -t AF
    bcftools index --tbi $vcf_out/split_vcf/gdio/$f
    bcftools view $vcf_out/split_vcf/gdio/$f > $vcf_out/split_vcf/gdio/textfiles/${gene}.txt
    python extract_genotypes.py $vcf_out gdio $gene

    bcftools view --samples-file $vcf_out/cohort_sample_lists/${gene}_llnext.txt --include ID==@$rsids $vcf_out/renamed_vcf/$f -o $vcf_out/split_vcf/llnext/no_AC/$f
    bcftools +fill-tags $vcf_out/split_vcf/llnext/no_AC/$f -o $vcf_out/split_vcf/llnext/$f -- -t AF
    bcftools index --tbi $vcf_out/split_vcf/llnext/$f
    bcftools view $vcf_out/split_vcf/llnext/$f > $vcf_out/split_vcf/llnext/textfiles/${gene}.txt
    python extract_genotypes.py $vcf_out llnext $gene

#    rm $vcf_out/renamed_vcf/$f
    bcftools query -f '%ID %CHROM %POS %REF %ALT %AC %AN %AF\n' $vcf_out/split_vcf/gdio/$f > $vcf_out/gdio_allele_counts_${gene}.txt
done

cat $vcf_out/genotypes/val/*.txt > $vcf_out/genotypes/val_all_genotypes.txt
cat $vcf_out/genotypes/gdio/*.txt > $vcf_out/genotypes/gdio_all_genotypes.txt
cat $vcf_out/genotypes/llnext/*.txt > $vcf_out/genotypes/llnext_all_genotypes.txt

rm -r $vcf_out/split_vcf/val/no_AC
rm -r $vcf_out/split_vcf/gdio/no_AC
rm -r $vcf_out/split_vcf/llnext/no_AC

cat $vcf_out/gdio_allele_counts_*.txt > $vcf_out/gdio_allele_counts.txt
rm $vcf_out/gdio_allele_counts_*.txt
