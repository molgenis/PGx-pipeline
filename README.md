# PGx-pipeline
Farmacogenetics pipeline

Preprocessing steps:
1. convert idat to gtc (on copperfist run AGCT pipeline)
2. copy patient GTC data to /groups/umcg-pgx/tmp07/rawdata/gtc/
3. create new folder in /groups/umcg-pgx/tmp07/rawdata/hematologie_research_data (e.g. Jackie-Augustus)
4. go to the folder and symlink patient GTC data (ln -s /groups/umcg-pgx/tmp07/rawdata/gtc/{PATIENTDATA} )
5. create a new folder (on the level of Jackie-Augustus) called Jackie-Augustus_plusGDIO (this will be a combination of	possibly multiple gtc data)
6. go in the Jackie-Augustus_plusGDIO folder and do following command: ln -s ../Jackie-Augustus/* .
7. still in GTC folder run this command: ln -s ../../GDIO/GTC/* .
8. combine samplesheets of GDIO (/groups/umcg-pgx/tmp07/rawdata/GDIO/GDIO.csv), with the analysing samples samplesheet, be aware of mismatching columns

e.g
PROJECT=Jackie-Augustus_plusGDIO
SAMPLESHEET=${PROJECT}.csv
```
mkdir /groups/umcg-pgx/tmp07/generatedscripts/${PROJECT}
module load PGx
cp ${EBROOTPGX}/generate_template.sh /groups/umcg-pgx/tmp07/generatedscripts/${PROJECT}/

cp ${SAMPLESHEET} /groups/umcg-pgx/tmp07/generatedscripts/${PROJECT}/
perl -p -e 's|project|originalProject|' ${SAMPLESHEET} > ${SAMPLESHEET}.tmp
awk -v project=${PROJECT} '{if(NR >1 ){print $0","project}else{ print $0",project"}}' ${SAMPLESHEET}.tmp > ${SAMPLESHEET}.tmp2
mv ${SAMPLESHEET}.tmp2 ${SAMPLESHEET}
bash generate_template.sh

bash submit.sh

```

