set -e
set -u

ml ${plink2Version}

mkdir -p $(dirname ${genotypesPlinkPrefix})

plink2 --data ${genotypesOxfordPrefix} 'ref-first' \
--extract ${variantsPassedQualityControl} \
--make-bed --out ${genotypesPlinkPrefix}

${sampleListPrefix}.samples.txt
