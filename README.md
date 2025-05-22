# PGx-pipeline
Farmacogenetics pipeline

Preprocessing steps:
1. convert idat to gtc (check if samplesheet contains analysis column instead of pipeline, important for copying rawdata to prm automatically)
2. copy GTC data to ```/groups/umcg-pgx/tmp07/rawdata/array/gtc/``` (use rsync -Lrv to copy the symlinks as files)
3. create new folder in ```/groups/umcg-pgx/tmp07/rawdata/hematologie_research_data``` (e.g. 2025_Apr_batch1)
4. in ```/groups/umcg-pgx/tmp07/rawdata/hematologie_research_data/2025_Apr_batch1``` make symlinks to the gtc folders from step2
5. create new folder in ```/groups/umcg-pgx/tmp07/rawdata/hematologie_research_data``` with GDIO data aswell (e.g. 2025_Apr_batch1_plusGDIO)
6. go in the 2025_Apr_batch1_plusGDIO folder and do following command: ```ln -s ../2025_Apr_batch1/* .```
7. still in GTC folder run this command: ```ln -s ../../GDIO/GTC/* .```
8. combine samplesheets of GDIO (```/groups/umcg-pgx/tmp07/rawdata/GDIO/GDIO.csv```), with the analysing samples samplesheet, **be aware of mismatching columns!**, call it 2025_Apr_batch1_plusGDIO.csv
10. rename **Project** in samplesheet to **originalProject** and add last column with headername **project** and fill in the name of the new project (2025_Apr_batch1_plusGDIO) this can be done via
```
perl -pi -e 's|Project|originalProject|' 2025_Apr_batch1_plusGDIO.csv
awk '{if (NR>1){print $0",2025_Apr_batch2_plusGDIO"}else{print $0",project"}}' 2025_Apr_batch1_plusGDIO.csv > 2025_Apr_batch1_plusGDIO.csv.tmp
```
after checking if correct, move the file to final location:
```
mv 2025_Apr_batch1_plusGDIO.csv.tmp /groups/umcg-pgx/tmp07/Samplesheets/2025_Apr_batch1_plusGDIO.csv
```

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
