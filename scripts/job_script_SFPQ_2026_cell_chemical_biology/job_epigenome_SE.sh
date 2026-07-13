#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l s_vmem=6G,mem_req=6G
#$ -pe def_slot 8
#$ -t 1-6
#$ -js 10

## -t 1-105

#i=$(expr ${SGE_TASK_ID} + 1)

i=${SGE_TASK_ID}

srr=`sed -n ${i}p ./samples.txt | cut -f 1`
name=`sed -n ${i}p ./samples.txt | cut -f 2`

thread=8
wget=false
fasterq=true
fastp=true
bowtie2=true
bam2cov=true
macs2=true

rm_fasterq=true
rm_fastp=true

mkdir -p /home/shiro2/colob/SFPQ/BELD/scripts/log
log_dir=/home/shiro2/colob/SFPQ/BELD/scripts/log

fq_ext=fastq

inp_dir=/home/shiro2/colob/SFPQ/BELD/00_rawdata
bowtie_index=/home/shiro2/Ref/bowtie_index/GRCm39/GRCm39
exclude=/home/shiro2/Ref/mm39.excluderanges.bed
#mm,hs,ce
macs2_species=mm

coverage=bigwig
#(bigwig,bedgraph or both)

cd ../

url1=""
url2=""

# arg1($name) are different among treatments.
. ~/script/epigenome/epigenome_SE.sh \
	${name}

