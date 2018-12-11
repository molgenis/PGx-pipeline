module load Java

java -jar -Xmx12g -XX:ParallelGCThreads=8 -Djava.io.tmpdir=${TMPDIR} /groups/umcg-wijmenga/tmp04/umcg-hbrugge/apps/generate-samplesheet.jar \
   --samplesheet \
   -i 
   -b 


