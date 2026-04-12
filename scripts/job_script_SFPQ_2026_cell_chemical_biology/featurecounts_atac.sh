#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l s_vmem=5G,mem_req=5G
#$ -pe def_slot 8

. ~/script/conda.sh
conda activate RNA-seq-py3

cd ../02_bowtie/

mkdir -p ../featurecounts

featureCounts -s 0 -T 8 -O -p \
        -t transcript -g gene_id \
        -a ~/Ref/gencode.vM35.annotation_ensemblcan_internal.gtf \
        -o ../featurecounts/MM_forbrain_E13.5_epigenome_tx_counts_atac_int.txt \
        MM_forbrain_E13.5_ATAC.bam
