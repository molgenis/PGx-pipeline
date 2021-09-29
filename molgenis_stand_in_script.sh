#!/bin/bash

# This script bridges the gap between a slurm array job
# and molgenis protocols. The aim is that this is more
# transparent and easier to work with than the molgenis
# compute stuff.

# The first job of this script is to forward all parameters
# to the protocol of choice.

# The second job of this script is to read parameters
# specific for this array index, and pass these also
# to the protocol of choice

jobdir='${SLURM_JOB_ID}_${SLURM_ARRAY_TASK_ID}'

source '${jobdir}/params.sh'
source '${parameters}'

source '${protocol}'