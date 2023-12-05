#MOLGENIS walltime=00:40:00 mem=40gb ppn=1

#string Project

# string parametersQcPath
# string genSampleDir
# string codedir
# string MAFref
# string

module load PLINK/1.9-beta6-20190617
module load RPlus
set -u
set -e

InputDir=${genSampleDir}
GeneralQCDir=${sampleQcDir}

source ${pipelineRoot}/scripts/QC_autosomes_launch.sh