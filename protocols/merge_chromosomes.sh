#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=4

### variables to help adding to database (have to use weave)
###

#string stage
#string checkStage

#Load modules

#Check modules
${checkStage}

echo "## "$(date)" Start $0"


for currentBed in *.bed; do
    if python ${} \
        --method unique \
        -I ${currentBed} \
        -S ${}/${}/$(basename ${})
    then
    	echo "returncode: $?";
        echo "dedupped bed ${}";
    else
    	echo "returncode: $?";
        echo "fail";
    fi
done

echo "## "$(date)" ##  $0 Done "

