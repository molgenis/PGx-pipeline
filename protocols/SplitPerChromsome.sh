#MOLGENIS walltime=23:59:00 nodes=1 mem=20gb ppn=4

### variables to help adding to database (have to use weave)
#string projectDir
###
#string stage
#string checkStage
#string splitChromInputDir
#string splitChromOutputDir

#Load modules
${stage} plink

#check modules
${checkStage}

echo "## "$(date)" Start $0"

for chr in {1..22} 
do

  plink --data ${splitChromInputDir}/chr_${chr} \
        --make-bed  \
        --missing \
        --out ${splitChromOutputDir}/chr_${chr}

then
 echo "returncode: $?";
else
 echo "returncode: $?";
 echo "fail";
fi

echo "## "$(date)" ##  $0 Done "
