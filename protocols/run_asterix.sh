#MOLGENIS walltime=23:59:00 mem=500mb nodes=1 ppn=4

#string chromosomeNumber
#string genotypesPlinkPrefix
#string javaVersion
#string nextflowPath
#string pgxGenesBed38
#string pgxGenesBed38Flanked
#string concatenatedGenotypesOutputDir
#string imputationPipelineReferencePath
#string imputationOutputDir
#string outputName

set -e
set -u

# Load required modules
module load ${javaVersion}

opticallPrefix
