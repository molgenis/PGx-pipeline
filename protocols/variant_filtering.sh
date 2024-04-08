set -e
set -u

ml ${plink2Version}

plink2 --data ${opticallPrefix} \
--extract ${variantsPassedQualityControl} \
--make-bed --out ${genotypesPlinkPrefix}

${sampleListPrefix}.samples.txt