set -e
set -u

ml ${plink2Version}

###create working directories
plink2 --data ${cnvOutDir}.reweighed_b_dosage \
--make-bed --out ${cnvOutDir}.reweighed_b_dosage

# Exclude CYP2D6 region from combined plink dataset
# Merge updated CYP2D6 genotype calls with main dataset
plink2 --bfile ${concatenatedGenotypesOutputDir}/chr_all \
--exclude range ${cnvBedFile} \
--pmerge ${cnvOutDir}.reweighed_b_dosage.bed ${cnvOutDir}.reweighed_b_dosage.bim ${cnvOutDir}.reweighed_b_dosage.fam \
--make-bed --out ${concatenatedGenotypesOutputDir}/chr_all_filtered
