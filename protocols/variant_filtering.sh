set -e
set -u

ml ${plink2Version}

plink2 --data ${opticallFile} \
--extract ${variantsQcPassedBed} \
--make-bed --out ${genotypesPlinkPrefix}