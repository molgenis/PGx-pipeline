# PGx-pipeline
Farmacogenetics pipeline

Preprocessing steps:
1: convert idat to gtc
2: create new folder in /groups/umcg-pgx/tmp07/rawdata/hematologie_research_data (e.g. Jackie-Augustus)
3: create a subfolder GTC folder
4: copy data to Jackie-Augustus	(this will be original data)
5: create a new folder (on the level of Jackie-Augustus) called Jackie-Augustus_plusGDIO (this will be a combination of	possibly multiple gtc data)
6: go in the Jackie-Augustus_plusGDIO folder and do following command: ln -s ../Jackie-Augustus/* .
7: still in GTC folder run this command: ln -s ../../GDIO/GTC/* .
8: combine samplesheets of GDIO (/groups/umcg-pgx/tmp07/rawdata/GDIO/GTC/GDIO.csv), with the analysing samples samplesheet, be aware of mismatching columns

PROJECT=e.g. Jackie-Augustus_plusGDIO
SAMPLESHEET= e.g. Jackie-Augustus_plusGDIO.csv
```
mkdir /groups/umcg-pgx/tmp07/generatedscripts/{PROJECT}
module load PGx
cp ${EBROOTPGX}/generate_template.sh /groups/umcg-pgx/tmp07/generatedscripts/{PROJECT}/
cp SAMPLESHEET /groups/umcg-pgx/tmp07/generatedscripts/{PROJECT}/
bash generate_template.sh

bash submit.sh

```

