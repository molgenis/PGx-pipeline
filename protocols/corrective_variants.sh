#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=8

### variables to help adding to database (have to use weave)
###


#string genotypesDir
#string correctiveVariantsOutputDir

#Load module
module load "${plinkVersion}"

mkdir -p ${correctiveVariantsOutputDir}

echo $'6\t28477797\t35000000\tHLA\n' > hla_range.bed

for chr in {1..22}
do

  correctiveVariantFiles+=("${correctiveVariantsOutputDir}/chr_${chr}.prune.in")

  plink \
    --bfile ${genotypesDir}/chr_${chr} \
    --out ${correctiveVariantsOutputDir}/chr_${chr}\
    --geno 0.01 \
    --maf 0.05 \
    --hwe 1e-6 \
    --exclude 'range' hla_range.bed \
    --bp-space 100000 \
    --indep-pairwise 500 5 0.4

done

cat ${correctiveVariantFiles[@]} > "${correctiveVariantsOutputDir}/merged.prune.in"