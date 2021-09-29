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

cd "${SLURM_JOB_NAME}_${SLURM_ARRAY_TASK_ID}"

echo "Running the following protocol: ${protocol}"
source "params.sh"

echo "Starting..."
bash ${protocol}