ml DBD-mysql/4.048-foss-2018b-Perl-5.28.0
ml BEDTools/2.28.0-GCCcore-7.3.0

mysql --user=genome --host=genome-mysql.cse.ucsc.edu -A -e "select chrom, size from hg19.chromInfo" | \
sed '2,$s/chr//g' > hg19.genome

bedtools slop -b 1000000 -i ./pgx-genes_GRCh37.bed -g hg19.genome > \
./pgx-genes_GRCh37_1Mb-flanks.bed

mysql --user=genome --host=genome-mysql.cse.ucsc.edu -A -e "select chrom, size from hg38.chromInfo" | \
sed '2,$s/chr//g' > hg38.genome

bedtools slop -b 1000000 -i ./pgx-genes_GRCh38.bed -g hg38.genome > \
./pgx-genes_GRCh38_1Mb-flanks.bed
