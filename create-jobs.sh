#!/usr/bin/env bash

module load Molgenis-Compute
module load Java


#Generate jobs
sh $EBROOTMOLGENISMINCOMPUTE/molgenis_compute.sh \
--backend slurm \
--generate \
--header header.ftl \
-p parameters.converted.csv \
-p samplesheet.csv \
-w ./workflow-no-split.csv \
-rundir jobs/ \
--weave

