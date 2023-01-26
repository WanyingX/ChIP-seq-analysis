#!/bin/bash

expt=$1
fq1=$2
fq2=$3

ref=${Mapping reference: Index created by bowtie2 on current version of reference genome}

bowtie2 --no-unal --no-mixed --no-discordant -p 8 -q --phred33 -I 10 -X 700 --threads 12 -x $ref -1 $fq1 -2 $fq2 | samtools view -bS - > ${expt}.bam

ref=${Decoded reference: Index created by samtools on current version of reference genome}

# sort and only keep the uniquely mapped read

samtools view -bS -t $ref $expt.bam | samtools sort - | samtools view -h -F 4 -b - > $expt.sorted.bam

# Count uniquely mapped reads

echo $expt uniquely mapped read `samtools view -c $expt.sorted.bam | awk '{print $1/2}'` >> $expt.summary

# Remove PCR-duplicates by picard

java -jar picard.jar MarkDuplicates \
      REMOVE_DUPLICATES=true \
      I=$expt.sorted.bam \
      O=$expt.duplicatedRemoved.bam \
      M=marked_dup_metrics.txt

# Count non-duplicated read

echo $expt Non-duplicated read `samtools view -c $expt.duplicatedRemoved.bam | awk '{print $1/2}'` >> $expt.summary

lib=/mnt/rstor/genetics/JinLab/xxl244/lib

samtools sort -n $expt.duplicatedRemoved.bam | samtools view -bf 2  | bedtools bamtobed -bedpe -i stdin | awk -v OFS='\t' '{print $1,$2,$6,".",1}' | $lib/sorted_bed_merge_redundant_lines_V2.pl | sort -k1,1 -k2,2n -k3,3n > $expt.monoclonal.bed

bedtools genomecov -bg -i $expt.monoclonal.bed -g $chrom_size > $expt.monoclonal.bed.bg
$software/bedGraphToBigWig $expt.monoclonal.bed.bg $chrom_size $expt.monoclonal.bed.bw

wait
exit


