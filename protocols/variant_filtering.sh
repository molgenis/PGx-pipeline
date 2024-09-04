set -e
set -u

ml ${plink2Version}
ml ${RPlusVersion}
export R_LIBS_USER=${rLibsPath}

mkdir -p $(dirname ${genotypesPlinkPrefix})
mkdir -p $(dirname ${sampleListPrefix})

plink2 --data ${genotypesOxfordPrefix} 'ref-first' \
--extract ${variantsPassedQualityControl} \
--make-bed --out ${genotypesPlinkPrefix}