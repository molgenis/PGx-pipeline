#MOLGENIS walltime=02:00:00 mem=10gb ppn=1

#string ngsUtilsVersion
#string PLINKVersion
#string Sample_ID
#string arrayFinalReport
#string PlinkDir
#string familyList
#string famFile
#string lgenFile
#string arrayTmpMap
#string arrayMapFile
#string Project
#string logsDir
#string PLINKVersion2
#string BEDtoolsVersion
#string HRCFilterBedFile
#string HTSlibVersion
#string BCFtoolsVersion
#list chr

set -e
set -u

#Function to check if array contains value
array_contains () {
    local array="$1[@]"
    local seeking=$2
    local in=1
    for element in "${!array-}"; do
        if [[ "${element}" == "${seeking}" ]]; then
            in=0
            break
        fi
    done
    return "${in}"
}


makeTmpDir "${PlinkDir}"
tmpPlinkDir="${MC_tmpFile}"


#Check finalReport on "missing" alleles. Also, see if we can fix missing alleles somewhere in GenomeStudio
awk '{ if ($3 != "-" || $4 != "-") print $0};' "${arrayFinalReport}/${Sample_ID}.txt" \
> "${tmpPlinkDir}/${Sample_ID}_FinalReport.txt.tmp"

#Check finalreport on "D"alleles.
awk '{ if ($3 != "D" || $4 != "D") print $0};' "${tmpPlinkDir}/${Sample_ID}_FinalReport.txt.tmp" \
> "${tmpPlinkDir}/${Sample_ID}_FinalReport_2.txt.tmp"

#Push sample belonging to family "1" into list.txt

sampleValue=$(awk 'FNR == 8 {print$2}' "${arrayFinalReport}/${Sample_ID}.txt")

echo 1 "${sampleValue}" > "${tmpPlinkDir}/${familyList}"

#########################################################################
#########################################################################

module load "${ngsUtilsVersion}"
module load "${PLINKVersion}"
module list

##Create .fam, .lgen and .map file from sample_report.txt
sed -e '1,10d' "${tmpPlinkDir}/${Sample_ID}_FinalReport_2.txt.tmp" | awk '{print "1",$2,"0","0","0","1"}' | uniq > "${tmpPlinkDir}/${famFile}"
sed -e '1,10d' "${tmpPlinkDir}/${Sample_ID}_FinalReport_2.txt.tmp" | awk '{print "1",$2,$1,$3,$4}' | awk -f "${EBROOTNGSMINUTILS}/RecodeFRToZero.awk" > "${tmpPlinkDir}/${lgenFile}"
sed -e '1,10d' "${tmpPlinkDir}/${Sample_ID}_FinalReport_2.txt.tmp" | awk '{print $6,$1,"0",$7}' OFS="\t" | sort -k1n -k4n | uniq > ${tmpPlinkDir}/${arrayTmpMap}
grep -P '^[123456789]' "${tmpPlinkDir}/${arrayTmpMap}" | sort -k1n -k4n > "${tmpPlinkDir}/${arrayMapFile}"
grep -P '^[X]\s' "${tmpPlinkDir}/${arrayTmpMap}" | sort -k4n >> "${tmpPlinkDir}/${arrayMapFile}"
grep -P '^[Y]\s' "${tmpPlinkDir}/${arrayTmpMap}" | sort -k4n >> "${tmpPlinkDir}/${arrayMapFile}"

#####################################
##Create .bed and other files (keep sample from sample_list.txt).
##Create .bed and other files (keep sample from sample_list.txt).


#Create ped and map file
plink \
--lfile "${tmpPlinkDir}/${Sample_ID}" \
--recode \
--noweb \
--out "${tmpPlinkDir}/${Sample_ID}" \
--keep "${tmpPlinkDir}/${familyList}"

#Convert ped and map files to a VCF file

#Use different version from plink to make the VCF file
module unload plink
module load "${PLINKVersion2}"
module list

##Create genotype VCF for sample
	plink \
	--recode vcf-iid \
	--ped "${tmpPlinkDir}/${Sample_ID}.ped" \
	--map "${tmpPlinkDir}/${arrayMapFile}" \
	--out "${tmpPlinkDir}/${Sample_ID}"


# Filter VCF file with bed file of SNPs from HRC with a MAF value lower than 0.01 .
# we want to exclude those SNP's so we use the -v option from bedtools intersect


module load "${BEDtoolsVersion}"
module load "${HTSlibVersion}"
module list

bedtools intersect -a "${tmpPlinkDir}/${Sample_ID}.vcf" -b "${HRCFilterBedFile}" -v -header >  ${tmpPlinkDir}/${Sample_ID}.filteredMAF.vcf

bgzip -c "${tmpPlinkDir}/${Sample_ID}.filteredMAF.vcf" > "${tmpPlinkDir}/${Sample_ID}.filteredMAF.vcf.gz"
tabix -p vcf "${tmpPlinkDir}/${Sample_ID}.filteredMAF.vcf.gz"

# Make an VCF per chromosome

chromsomes=()

for chromosome in "${chr[@]}"
do
	array_contains chromosomes "${chromosome}" || chromosomes+=("$chromosome")
done

for chr in ${chromosomes[@]}
do
	tabix -h "${tmpPlinkDir}/${Sample_ID}.filteredMAF.vcf.gz" "${chr}" > "${tmpPlinkDir}/chr${chr}_${Sample_ID}.filteredMAF.vcf"
done

#Remove duplicate SNP's from the VCF files

module load "${BCFtoolsVersion}"

for chr in ${chromosomes[@]}
do
bcftools norm -d any "${tmpPlinkDir}/chr${chr}_${Sample_ID}.filteredMAF.vcf" -O v -o "${tmpPlinkDir}/chr${chr}_${Sample_ID}.filteredMAF_duplicatesRemoved.vcf"
done


# Convert per chromosome VCF's to .bed , .bim , .fam format PLINK which can be used as phasing input

for chr in ${chromosomes[@]}
do
	plink \
        --vcf "${tmpPlinkDir}/chr${chr}_${Sample_ID}.filteredMAF_duplicatesRemoved.vcf" \
        --make-bed \
        --out "${tmpPlinkDir}/chr${chr}_${Sample_ID}"
done


# Move output to output folder

for chr in ${chromosomes[@]}
do
	echo "mv temporaru results from ${tmpPlinkDir} to ${PlinkDir}"
	mv "${tmpPlinkDir}/chr${chr}_${Sample_ID}.filteredMAF_duplicatesRemoved.vcf" "${PlinkDir}"
	mv "${tmpPlinkDir}/chr${chr}_${Sample_ID}.bed" "${PlinkDir}"
	mv "${tmpPlinkDir}/chr${chr}_${Sample_ID}.bim" "${PlinkDir}"
	mv "${tmpPlinkDir}/chr${chr}_${Sample_ID}.fam" "${PlinkDir}"

done

