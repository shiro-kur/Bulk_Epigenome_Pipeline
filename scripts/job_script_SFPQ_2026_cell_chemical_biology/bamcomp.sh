#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -l s_vmem=8G,mem_req=8G
#$ -pe def_slot 8
#$ -js 1000000

. ~/script/conda.sh
conda activate RNA-seq-py3.10

cd ../03_bam2cov/

bamCompare \
	-p 2 \
	-b1 ../02_bowtie/MM_forbrain_E13.5_H3K27ac.bam \
	-b2 ../02_bowtie/MM_forbrain_E13.5_input.bam \
	-o MM_forbrain_E13.5_H3K27ac-input_1bp.bw \
	--scaleFactorsMethod None \
	--normalizeUsing CPM \
	--operation subtract \
	--binSize 1
	
bamCompare \
	-p 2 \
        -b1 ../02_bowtie/MM_forbrain_E13.5_H3K4me1.bam \
        -b2 ../02_bowtie/MM_forbrain_E13.5_input.bam \
        -o MM_forbrain_E13.5_H3K4me1-input_1bp.bw \
        --scaleFactorsMethod None \
	--normalizeUsing CPM \
        --operation subtract \
        --binSize 1
