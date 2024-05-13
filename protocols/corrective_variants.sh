#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=8

### variables to help adding to database (have to use weave)
###

#string plinkVersion
#string genotypesDir
#string correctiveVariantsOutputDir

#Load module
module load "${plinkVersion}"

mkdir -p ${correctiveVariantsOutputDir}

echo $'6\t28477797\t35000000\tHLA\n' > hla_range.bed

for genotypesPlinkPrefix in "${genotypesPlinkPrefixArray[@]}"
do

  basePlinkPrefix=$(basename ${genotypesPlinkPrefix})

  correctiveVariantFiles+=("${correctiveVariantsOutputDir}/${basePlinkPrefix}.prune.in")

  plink \
    --bfile ${genotypesPlinkPrefix} \
    --out ${correctiveVariantsOutputDir}/${basePlinkPrefix}\
    --geno 0.01 \
    --maf 0.05 \
    --hwe 0.01 \
    --exclude 'range' hla_range.bed \
    --bp-space 100000 \
    --indep-pairwise 500 5 0.4

done

cat "${correctiveVariantFiles[@]}" > ${correctiveVariantsOutputDir}/merged.prune.in

module purge
module load "${pythonVersion}"
module list

source ${pythonEnvironment}/bin/activate

python ${asterixRoot}/src/main/python/cnvcaller/core.py variants \
  --bead-pool-manifest "${bpmFile}" \
  --sample-list "${sampleListPrefix}.samples.txt" \
  --bed-file "${cnvBedFile}" \
  --corrective-variants "${correctiveVariantsOutputDir}/merged.prune.in" \
  --window 250kb \
  --config ${asterixRoot}/src/main/python/cnvcaller/conf/config.yml \
  --out "${correctiveVariantsOutputDir}"