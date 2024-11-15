#MOLGENIS walltime=23:59:00 mem=2gb nodes=1 ppn=4

### variables to help adding to database (have to use weave)
###

#list genotypesPlinkPrefix
#string concatenatedGenotypesOutputDir
#string plinkVersion
#string intermediateDir

set -e
set -u

#Function to check if array contains value
array_contains () {
	local array="$1[@]"
	local seeking="${2}"
	local in=1
	for element in "${!array-}"; do
		if [[ "${element}" == "${seeking}" ]]; then
			in=0
			break
		fi
	done
	return "${in}"
}


#Load modules
module load "${plinkVersion}"

#Check modules
module list
mkdir -p "${concatenatedGenotypesOutputDir}"
INPUTS=()

for genotypes in "${genotypesPlinkPrefix[@]}"
do
	array_contains INPUTS "${genotypes}" || INPUTS+=("${genotypes}")    # If bamFile does not exist in array add it

done

printf "%s\n" "${INPUTS[@]}" > "${intermediateDir}/files_to_merge.txt"

plink --merge-list "${intermediateDir}/files_to_merge.txt" --make-bed --out "${concatenatedGenotypesOutputDir}/plink_dataset_to_qc"

