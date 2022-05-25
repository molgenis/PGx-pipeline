#MOLGENIS walltime=02:00:00 mem=2gb ppn=1

#string pythonVersion
#string pythonEnvironment
#string bpmFile
#string pgxGenesBed37
#string cnvBedFile
#string pipelineRoot
#string arrayStagedIntensities
#string sampleListPrefix

set -e
set -u

# First load the RPlus version and set the R package library
# to obtain a list of samples on which we can perform cnv calling
module load ${RPlusVersion}
module list

R_LIBS=${rLibsPath}

mkdir -p $(dirname ${sampleListPrefix})

Rscript ${pipelineRoot}/scripts/map_genotype_samples.R \
--mapping ${sample_id_mapping_file} \
--samplesheet ${samplesheet} \
--gid-col "UGLI_ID" --sid-col "genotyping_name" --out ${sampleListPrefix}
