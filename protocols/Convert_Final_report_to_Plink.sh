#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

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

set -e
set -u

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

plink \
--lfile "${tmpPlinkDir}/${Sample_ID}" \
--recode \
--noweb \
--out "${tmpPlinkDir}/${Sample_ID}" \
--keep "${tmpPlinkDir}/${familyList}"

