# PGx-pipeline
Farmacogenetics pipeline

Preprocessing steps:
1. convert idat to gtc (check if samplesheet contains analysis column instead of pipeline, important for copying rawdata to prm automatically)
2. copy GTC data to /groups/umcg-pgx/tmp07/rawdata/array/gtc/ (use rsync -Lrv to copy the symlinks as files)
3. create new folder in /groups/umcg-pgx/tmp07/rawdata/hematologie_research_data (e.g. 2025_Apr_batch1)
4. in /groups/umcg-pgx/tmp07/rawdata/hematologie_research_data/2025_Apr_batch1 make symlinks to the gtc folders from step2
5. create new folder in /groups/umcg-pgx/tmp07/rawdata/hematologie_research_data with GDIO data aswell (e.g. 2025_Apr_batch1_plusGDIO)
9. go in the 2025_Apr_batch1_plusGDIO folder and do following command: ln -s ../2025_Apr_batch1/* .
10. still in GTC folder run this command: ln -s ../../GDIO/GTC/* .
11. combine samplesheets of GDIO (/groups/umcg-pgx/tmp07/rawdata/GDIO/GDIO.csv), with the analysing samples samplesheet, be aware of mismatching columns
12. rename Project in samplesheet to originalProject and add last column with headername 'project' and fill in the name of the new project (2025_Apr_batch1_plusGDIO)
13. copy samplesheet to /groups/umcg-pgx/tmp07/Samplesheets/

example: 
```
PROJECT=2025_Apr_batch1_plusGDIO
SAMPLESHEET=2025_Apr_batch1_plusGDIO.csv

mkdir -p /groups/umcg-pgx/tmp07/generatedscripts/${PROJECT}
module load PGx
cp ${EBROOTPGX}/generate_template.sh /groups/umcg-pgx/tmp07/generatedscripts/${PROJECT}/
cp /groups/umcg-pgx/tmp07/Samplesheets/${SAMPLESHEET} /groups/umcg-pgx/tmp07/generatedscripts/${PROJECT}/
cd /groups/umcg-pgx/tmp07/generatedscripts/${PROJECT}/
bash generate_template.sh

cd /groups/umcg-pgx//tmp07/projects/${PROJECT}/jobs
bash submit.sh

```


