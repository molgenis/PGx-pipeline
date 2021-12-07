#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=4

### variables to help adding to database (have to use weave)
###

#array genotypesPlinkPrefix
#string concatenatedGenotypesPlinkPrefix
#string plinkVersion

set -e
set -u

#Load modules
module load ${plinkVersion}

#Check modules
module list

printf "%s\n" "${genotypesPlinkPrefix[@]}" > files_to_merge.txt

plink --merge-list files_to_merge.txt --make-bed --out ${concatenatedGenotypesPlinkPrefix}

