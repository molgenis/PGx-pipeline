#MOLGENIS walltime=23:59:00 mem=16gb nodes=1 ppn=8

### variables to help adding to database (have to use weave)
###

#string stage
#string checkStage

#string shapeitVersion
#string phasingInputDir
#string phasingOutputDir
#string refDir
#string mapDir

#Load module
${stage} shapeitVersion

#Check modules
${checkStage}

mkdir -p ${phasingOutputDir}

for chr in {1..22}
do
	shapeit \
        -B ${phasingOutputDir}/chr_${chr} \
        -M ${mapDir}/genetic_map_chr${chr}_combined_b37.txt \
        --input-ref ${refDir}/${chr}.impute.hap \
        -O ${outputFolder}/chr_${chr} \
        --output-log ${outputFolder}/chr_${chr}.log \
        --thread 8
done
