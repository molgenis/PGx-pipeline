#MOLGENIS walltime=02:00:00 mem=20gb ppn=1
#string plink2Version
#string cnvOutDir
#string concatenatedGenotypesOutputDir
#string cnvBedFile
#string plinkVersion

set -e
set -u

ml ${plink2Version}

###create working directories
plink2 --data "${cnvOutDir}.reweighed_b_dosage" 'ref-first' \
--make-bed --out "${cnvOutDir}.reweighed_b_dosage"

awk 'BEGIN{FS="\t"; OFS=FS} { print $2 }' "${cnvOutDir}.reweighed_b_dosage.bim" > "${cnvOutDir}.variant_list.txt"

# Exclude CYP2D6 region from combined plink dataset
# Merge updated CYP2D6 genotype calls with main dataset
plink2 --bfile "${concatenatedGenotypesOutputDir}/chr_all" \
--exclude range "${cnvBedFile}" --keep "${cnvOutDir}.reweighed_b_dosage.fam" --chr 22 \
--make-bed --out 'chr_22_filtered'

ml "${plinkVersion}"

mkdir -p "${cnvOutDir}.integrated_genotypes_filtered"

plink --bfile 'chr_22_filtered' \
--bmerge "${cnvOutDir}.reweighed_b_dosage.bed" "${cnvOutDir}.reweighed_b_dosage.bim" "${cnvOutDir}.reweighed_b_dosage.fam" \
--make-bed --out "${cnvOutDir}.integrated_genotypes_filtered/chr_22"
