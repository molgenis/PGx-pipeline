#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=4

### variables to help adding to database (have to use weave)
###

#array genotypesPgxFilteredArray
#string genotypesPgxFilteredOutputDir
#string plinkVersion

set -e
set -u

#Load modules
ml ${plinkVersion}

#Check modules
${checkStage}

printf "%s\n" "${genotypesPgxFilteredArray[@]}" > files_to_merge.txt

plink --merge-list files_to_merge.txt --make-bed --out ${genotypesPgxFilteredOutputDir}/chr_all

