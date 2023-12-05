set -e
set -u

###create working directories
mkdir -p "${sampleQcDir}/0_pre"

bash ${codedir}/sub1.gensample_to_plink.sh \
  ${sampleQcDir}/0_pre/ \
  ${genSampleDir} \
  ${chrNr}