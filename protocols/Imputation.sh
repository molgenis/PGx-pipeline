#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=8

### variables to help adding to database (have to use weave)
###


#string stage
#string checkStage

#string impute2Version
#string imputationInputDir
#string imputationOutputDir
#string refDir
#string mapDir
#string m
#string h
#string l
#string fromChrPos
#string toChrPos

#Load module
${stage} impute2Version

#Check modules
${checkStage}

mkdir -p ${imputationOutputDir}

for chr in {1..22}
do

impute2 \
    -known_haps_g $known_haps_g/chr_${chr} \
    -m $m/chr_${chr} \
    -h $h/chr_${chr} \
    -l $l/chr_${chr} \
    -int $fromChrPos $toChrPos \
    -o imputationOutputDir/chr_${chr}\
    -use_prephased_g \
    $additonalImpute2Param

done