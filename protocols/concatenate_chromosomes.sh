#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=4

### variables to help adding to database (have to use weave)
###

#array genotypesPlinkPrefixArray
#string concatenatedGenotypesOutputDir
#string plinkVersion

set -e
set -u

#Load modules
module load ${plinkVersion}

#Check modules
module list

printf "%s\n" "${genotypesPlinkPrefixArray[@]}" > files_to_merge.txt

plink --merge-list files_to_merge.txt --make-bed --out ${concatenatedGenotypesOutputDir}/chr_all

