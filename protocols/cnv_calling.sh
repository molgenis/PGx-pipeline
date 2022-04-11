#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string pythonEnvironment
#string bpmFile
#string pgxGenesBed37
#string cnvBedFile
#string pipelineRoot
#string arrayStagedIntensities
#string sampleList

set -e
set -u

# First load the RPlus version and set the R package library
# to obtain a list of samples on which we can perform cnv calling
module load ${RPlusVersion}
module list

R_LIBS=${rLibsPath}

mkdir -p ${cnvOutDir}

Rscript ${pipelineRoot}/scripts/map_genotype_samples.R \
--mapping ${toUgliIdentifiers} \
--samplesheet ${samplesheet} \
--gid-col "UGLI_ID" --sid-col "genotyping_name" --out "samples_to_select"

# Now laod the python version and activate the python environment
# to perform cnv calling
module load "${pythonVersion}"
module list

source ${pythonEnvironment}/bin/activate

python ${asterixRoot}/src/main/python/cnvcaller/core.py fit \
  --bead-pool-manifest "${bpmFile}" \
  --sample-list "samples_to_select.samples.txt" \
  --variants-prefix "${correctiveVariantsOutputDir}" \
  --out "${cnvOutDir}" \
  --input "${arrayStagedIntensities[@]}" \
  --config ${asterixRoot}/src/main/python/cnvcaller/conf/config.yml
