#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=8

### variables to help adding to database (have to use weave)
###


#string genotypesDir
#string correctiveVariantsOutputDir

#Load module
module load "${plinkVersion}"

mkdir -p ${correctiveVariantsOutputDir}

for chr in {1..22}
do
  # First we want to eliminate variants that have a MAF of 5% or lower:

  plink \
    --bfile ${genotypesDir}/chr_${chr} \
    --out ${correctiveVariantsOutputDir}/chr_${chr}\
    --geno 0.01 \
    --maf 0.05 \
    --hwe 0.01 \
    --indep-pairwise "500kb" "5" "0.4"

done