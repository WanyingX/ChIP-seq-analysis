#!/bin/bash

genome=$1

# Build your path for code and reference file
lib=

if [ $genome == "mm10" ];then 
	index=$ref/mm10.fa.fai
	chrom_size=$ref/mm10.chrom.sizes
fi
if [ $genome == "hg19" ];then
	index=$ref/hg19.fa.fai
	chrom_size=$ref/hg19.chrom.sizes
fi

# for bowtie 
mm10=/mnt/rstor/genetics/JinLab/xxl244/Reference_Indexes/mm10_bowtie_index/mm10
for file in `ls *.fastq`;do
        ~/Chip_seq/bowtie_fastq.pl mm10 8 $file     #fastq -> sam
done 

#---------------Sam file to sorted mapped bam file----------------
for file in `ls *.sam`;do
	samtools view -bS -t $index $file | samtools sort -o ${file/.sam}.bam       #sam->sorted bam
	samtools view -h -F 4 -b ${file/.sam}.bam > ${file/.sam}.sorted.bam 	    #remove unmapped reads
done 

#---------------Sorted bam file to bed,wig and bigwig file-----------------------------
for file in `ls *.sorted.bam`;do
	name=${file/.sorted.bam/}
	bedtools bamtobed -i $file | awk '{OFS="\t";print $1,$2,$3,".","1"}' | $lib/sorted_bed_merge_redundant_lines_V2.pl > $name.monoclonal.bed     #bam -> bed -> aims to remove PCR duplication
	$lib/extend_reads_from_start.pl $name.monoclonal.bed 300 $genome | $lib/UCSC_2_normal.pl | sort -k1,1 -k2,2n -k3,3n | $lib/sorted_bed_2_wig_no_strand.pl | $lib/normal_2_UCSC.pl > $name.wig.300bp  #bed -> wig
	$lib/wigToBigWig $name.wig.300bp $chrom_size $name.bw  #wig ->bigwig
done 



