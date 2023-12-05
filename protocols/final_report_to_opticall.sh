#!/bin/bash

#MOLGENIS walltime=59:59:00 mem=20gb ppn=6

#string pythonVersion
#string beadArrayVersion
#string gapVersion
#string bpmFile
#string projectRawTmpDataDir
#string intermediateDir
#string tmpTmpdir
#string tmpDir
#string workDir
#string tmpName
#string Project
#string logsDir
#string finalReport
#string samplesheet
#string optiCallDir

set -e
set -u

mkdir -p "${optiCallDir}"

#makeTmpDir "${optiCallDir}/"
tmpOptiCallDir="tmp"

mkdir ${tmpOptiCallDir}

bash ${pipelineRoot}/scripts/GS_to_Opticall.sh -i "${finalReport}" -o "${tmpOptiCallDir}"

echo "mv ${tmpOptiCallDir}/chr_ ${optiCallDir}"
mv "${tmpOptiCallDir}/chr_"* "${optiCallDir}"
