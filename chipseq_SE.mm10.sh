#!/bin/bash

lib=/mnt/rstor/genetics/JinLab/xxl244/lib
jin=/mnt/rstor/genetics/JinLab/fxj45
www=$jin/WWW/xww/bigwig/
mm10=/mnt/rstor/genetics/JinLab/xxl244/Reference_Indexes/mm10_bowtie_index/mm10.fa.fai
chrom_size=/mnt/rstor/genetics/JinLab/xxl244/Reference_Indexes/mm10_bowtie_index/mm10.chrom.sizes

# for bowtie 
mm10=/mnt/rstor/genetics/JinLab/xxl244/Reference_Indexes/mm10_bowtie_index/mm10
for file in `ls *.fastq`;do
        ~/Chip_seq/bowtie_fastq.pl mm10 8 $file     #fastq -> sam
done 




#---------------Sam file to sorted mapped bam file----------------
for file in `ls *.sam`;do
	samtools view -bS -t $mm10 $file | samtools sort -o ${file/.sam}.bam       #sam->sorted bam
  #echo -ne ${file/.sam/} has `cat $file | wc -l` total reads.\\n >> summary.reads_count &
	wait
	samtools view -h -F 4 -b ${file/.sam}.bam > ${file/.sam}.sorted.bam 	#remove unmapped reads
done 

#---------------Sorted bam file to bed,wig and bigwig file-----------------------------
for file in `ls *.sorted.bam`;do
	name=${file/.sorted.bam/}
#	echo -ne $name has `samtools view $file | wc -l` mapped reads.\\n >>summary.reads_count
	bedtools bamtobed -i $file | awk '{OFS="\t";print $1,$2,$3,".","1"}' | $lib/sorted_bed_merge_redundant_lines_V2.pl > $name.monoclonal.bed     #bam -> bed
	wait
#	echo -ne $name has `wc -l $name.monoclonal.bed` monoclonal reads >>summary.reads_count
	~/Chip_seq/extend_reads_from_start.pl $name.monoclonal.bed 300 mm10 | $lib/UCSC_2_normal.pl | sort -k1,1 -k2,2n -k3,3n | $lib/sorted_bed_2_wig_no_strand.pl | $lib/normal_2_UCSC.pl > $name.wig.300bp  #bed -> wig
	wait
	/mnt/rstor/genetics/JinLab/xxl244/software/wigToBigWig $name.wig.300bp $chrom_size $name.bw  #wig ->bigwig
done 

#--------------------organize files------------------------------------------
#wait

