#!/bin/bash

expt=$1
mm10=/mnt/rstor/genetics/JinLab/xxl244/Reference_Indexes/mm10_bowtie_index/mm10
bowtie=/mnt/rstor/genetics/JinLab/xxl244/software/bowtie-1.1.2/bowtie

#bowtie2 -x $mm10 -p 4 -1 ${expt}_1.fastq -2 ${expt}_2.fastq 

length=`head ${expt}_1.fastq | tail -1 | wc -m`
#let length=$length-1
#let trlen=$length-36
$bowtie -v 2 -m 1 --best --strata --time -p 1 --sam $mm10 -1 ${expt}_1.fastq -2 ${expt}_2.fastq ${expt}.sam >> nohup.txt &	
wait
mm10=/mnt/rstor/genetics/JinLab/xxl244/Reference_Indexes/mm10_bowtie_index/mm10.fa.fai

samtools view -bS -t $mm10 $expt.sam | samtools sort - > $expt.sorted.bam &
wait

## call peaks with macs2

## merge all the peaks
java -jar ~/software/picard.jar MarkDuplicates \
      REMOVE_DUPLICATES=true \
      I=$expt.sorted.bam \
      O=$expt.duplicatedRemoved.bam \
      M=marked_dup_metrics.txt 
wait

lib=/mnt/rstor/genetics/JinLab/xxl244/lib
samtools sort -n $expt.duplicatedRemoved.bam |samtools view -bf 2  | bedtools bamtobed -bedpe -i stdin | awk -v OFS='\t' '{print $1,$2,$6,".",1}' | $lib/sorted_bed_merge_redundant_lines_V2.pl | sort -k1,1 -k2,2n -k3,3n > $expt.monoclonal.bed &
wait

chrom_size=/mnt/rstor/genetics/JinLab/xxl244/Reference_Indexes/mm10_bowtie_index/mm10.chrom.sizes


bedtools genomecov -bg -i $expt.monoclonal.bed -g $chrom_size > $expt.monoclonal.bed.bg &
wait
bedGraphToBigWig $expt.monoclonal.bed.bg $chrom_size $expt.monoclonal.bed.bw &

wait
exit
