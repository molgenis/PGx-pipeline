if test ! -e ${f};
then
	echo "name, step, nSNPs, PercDbSNP, Ti/Tv_known, Ti/Tv_Novel, All_comp_het_called_het, Known_comp_het_called_het, Non-Ref_Sensitivity, Non-Ref_discrepancy, Overall_concordance" > ${sampleConcordanceFile}
	echo "[1] NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA" >> ${sampleConcordanceFile} 
else
	#Check finalReport on "missing" alleles. Also, see if we can fix missing alleles somewhere in GenomeStudio
	awk '{ if ($3 != "-" || $4 != "-") print $0};' ${f} \
	> ${s}_FinalReport.txt.tmp

	#Check finalreport on "D"alleles.
	awk '{ if ($3 != "D" || $4 != "D") print $0};' ${s}_FinalReport.txt.tmp \
	> ${s}_FinalReport_2.txt.tmp

	#Push sample belonging to family "1" into list.txt
	echo 1 ${s} > ${familyList}

	#########################################################################
	#########################################################################

	module load ngs-utils/16.09.1

	##Create .fam, .lgen and .map file from sample_report.txt
	sed -e '1,10d' ${s}_FinalReport_2.txt.tmp | awk '{print "1",$2,"0","0","0","1"}' | uniq > ${s}.concordance.fam
	sed -e '1,10d' ${s}_FinalReport_2.txt.tmp | awk '{print "1",$2,$1,$3,$4}' | awk -f ${EBROOTNGSMINUTILS}RecodeFRToZero.awk > ${s}.concordance.lgen
	sed -e '1,10d' ${s}_FinalReport_2.txt.tmp | awk '{print $6,$1,"0",$7}' OFS="\t" | sort -k1n -k4n | uniq > ${arrayTmpMap}
	grep -P '^[123456789]' ${arrayTmpMap} | sort -k1n -k4n > ${arrayMapFile}
	grep -P '^[X]\s' ${arrayTmpMap} | sort -k4n >> ${arrayMapFile}
	grep -P '^[Y]\s' ${arrayTmpMap} | sort -k4n >> ${arrayMapFile}

	#####################################
	##Create .bed and other files (keep sample from sample_list.txt).

	##Create .bed and other files (keep sample from sample_list.txt).

	module load PLINK/1.07-x86_64
	module list

	plink \
	--lfile ${s}.concordance \
	--recode \
	--noweb \
	--out ${s}.concordance \
	--keep ${familyList}

