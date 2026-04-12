###Define Functions#######

source ~/script/pipeline_function.sh

###################Set Basics#################

. ~/script/conda.sh

sample=${1}
R1=${2}
R2=${3}

current=$(date +"%Y%m%d_%H%M%S")
log=${current}.${sample}
oup_log=${log_dir}/${log}.output.txt
err_log=${log_dir}/${log}.error.txt

oup_log2=${log}.output.txt
err_log2=${log}.error.txt

echo "EPIGENOME pipeline for single sample was started." > ${oup_log}

###################Wget###################

if [ "$wget" = true ]; then

	start=$(log_start "wget" "$oup_log")
	mkdir -p ./00_rawdata
	cd ./00_rawdata
	
	. ~/script/rna-pipe/wget_PE.sh
	finalize_process "wget" $start ${oup_log} ${err_log} ${R}.${fq_ext}.gz
	cd ../

else
	echo "Skipping wget" >> ${oup_log}
fi

###################Fasterq-dump###################

if [ "$fasterq" = true ]; then

	start=$(log_start "fasterq-dump" "${oup_log}")
	mkdir -p ./00_rawdata
	cd ./00_rawdata

	. ~/script/rna-pipe/fasterq_PE.sh 2> Fasterq.${err_log2} 1> Fasterq.${oup_log2}

	finalize_process "fasterq-dump" $start "${oup_log}" "${err_log}" "./${R2}.${fq_ext}.gz"
	cd ../

else
	echo "Skipping fasterq-dump" >> ${oup_log}

fi


###################FASTP###################

if [ "$fastp" = true ]; then

	conda activate epigenome

	start=$(log_start "fastp" "${oup_log}")
	mkdir -p ./01_fastp
	cd ./01_fastp

	fastp \
		-i ${inp_dir}/${R1}.${fq_ext}.gz \
		-I ${inp_dir}/${R2}.${fq_ext}.gz \
		-o ./${R1}.fastp.${fq_ext} \
		-O ./${R2}.fastp.${fq_ext} \
		-h ./${sample}.${fq_ext}.html \
		-j ./${sample}.${fq_ext}.json \
		-w ${thread} \
		2> Fastp.${err_log2} 1> Fastp.${oup_log2}

	finalize_process "Fastp" $start "${oup_log}" "${err_log}" "./${R2}.fastp.${fq_ext}"

	if [ "$rm_fasterq" = true ]; then
		rm ${inp_dir}/${R1}.${fq_ext}.gz
		rm ${inp_dir}/${R2}.${fq_ext}.gz
	fi

	cd ../
	
else
	echo "Skipping Fastp" >> ${oup_log}

fi

###################BOWTIE2###################

if [ "$bowtie2" = true ]; then

	conda activate epigenome
	
	start=$(log_start "BOWTIE2" "${oup_log}")
	mkdir -p ./02_bowtie
	cd ./02_bowtie

	bowtie2 \
		-p ${thread} \
		-t \
		--very-sensitive \
		--no-mixed \
		--no-discordant \
		--maxins 500 \
		-1 ../01_fastp/${R1}.fastp.${fq_ext} \
		-2 ../01_fastp/${R2}.fastp.${fq_ext} \
		-x ${bowtie_index} \
		-S ${sample}.sam \
		2> BT2.${oup_log2} &&

	samtools view \
		-@ ${thread} \
		-Sb ${sample}.sam -o ${sample}.pre.bam \
		>> BT2.${oup_log2} 2>&1  &&
		
	rm ${sample}.sam &&

	samtools sort \
		-@ ${thread} -o ${sample}.pre.sort.bam ${sample}.pre.bam \
		>> BT2.${oup_log2} 2>&1  &&

	rm ${sample}.pre.bam &&

	picard AddOrReplaceReadGroups \
		--INPUT ${sample}.pre.sort.bam \
		--OUTPUT ${sample}.pre.sort.RG.bam \
		--RGID ${sample} \
		--RGLB library1 \
		--RGPL ILLUMINA \
		--RGPU unit1 \
		--RGSM ${sample} \
		--CREATE_INDEX true \
		>> BT2.${oup_log2} 2>&1  &&

	rm ${sample}.pre.sort.bam &&

	picard -Xmx24g MarkDuplicates \
		--INPUT ${sample}.pre.sort.RG.bam \
		--OUTPUT ${sample}.pre.sort.markdup.bam \
		--ASSUME_SORTED true \
		--REMOVE_DUPLICATES false \
		--READ_NAME_REGEX null \
		--METRICS_FILE ${R}.MarkDuplicates.metrics.txt \
		--VALIDATION_STRINGENCY LENIENT \
		--TMP_DIR ${sample}.tmp \
		>> BT2.${oup_log2} 2>&1  &&

	rm ${sample}.pre.sort.RG.bam* &&

	samtools view \
		-@ ${thread} \
		-F 0x004 -F 0x0008 -f 0x001 \
		-F 0x0400 \
		-q 1 \
		-b ${sample}.pre.sort.markdup.bam \
		1> ${sample}.pre.sort.markdup.filt.bam \
		2>> BT2.${oup_log2} &&

	rm ${sample}.pre.sort.markdup.bam &&

	bedtools intersect \
		-a ${sample}.pre.sort.markdup.filt.bam \
		-b ${exclude} \
		-v \
		-ubam \
		1> ${sample}.bam \
		2>> BT2.${oup_log2} &&

	rm ${sample}.pre.sort.markdup.filt.bam &&	
	rm -r ${sample}.tmp &&
	
	samtools index ${sample}.bam &&

	finalize_process "bowtie2" $start "${oup_log}" "${err_log}" "${sample}.bam.bai"
	
	if [ "$rm_fastp" = true ]; then
                rm ../01_fastp/${R1}.fastp.${fq_ext} ../01_fastp/${R2}.fastp.${fq_ext}
	
	fi
	
	cd ../

else
	echo "Skipping BOWTIE2" >> ${oup_log}

fi

###################bamCoverage###################

if "${bam2cov}" ; then

	conda activate RNA-seq-py3.10 
	
	start=$(log_start "bamCoverage" "${oup_log}")
	mkdir -p ./03_bam2cov
	cd ./03_bam2cov
	
	if [ $coverage = "both" ] || [ $coverage = "bigwig" ] ; then
		bamCoverage \
			-p 1 \
			-b ../02_bowtie/${sample}.bam \
			-of bigwig \
			-o ./${sample}.bw \
			--binSize 1 \
			--normalizeUsing CPM \
			2> bamCov.${err_log2} 1> bamCov.${oup_log2}
	fi
	
	if [ $coverage = "both" ] || [ $coverage = "bedgraph" ] ; then
		bamCoverage \
			-p 1 \
			-b ../02_bowtie/${sample}.bam \
			-of bedgraph \
			-o ./${sample}.bedgraph \
			--normalizeUsing CPM \
			--binSize 1 \
			2> bamCov.${err_log2} 1> bamCov.${oup_log2}
	
	fi
	
	finalize_process "BamCoverage" $start "${oup_log}" "${err_log}" "./${sample}.bw"
	
	cd ../

else
	echo "Skipping BamCoverage" >> ${oup_log}
fi

###################MACS2#########################

if "${macs2}" ; then
	
	conda activate macs2
	
	start=$(log_start "MACS2" "${oup_log}")
	mkdir -p ./04_macs2
	cd ./04_macs2

	macs2 callpeak \
		-f BAMPE \
		-g ${macs2_species} \
		-t ../02_bowtie/${sample}.bam \
		-n ${sample} \
		-q 0.05 \
		2> MACS2.${err_log2} 1> MACS2.${oup_log2} &&
		
	macs2 callpeak \
		-f BAMPE \
		-g ${macs2_species} \
		-t ../02_bowtie/${sample}.bam \
		-n ${sample} \
		--broad \
		--broad-cutoff 0.1 \
		2>> MACS2.${err_log2} 1>> MACS2.${oup_log2}

	finalize_process "MACS2" $start "${oup_log}" "${err_log}" "./${sample}_peaks.narrowPeak"

	cd ../
else
	echo "Skipping MACS2" >> ${oup_log}
fi

###################################################


echo "Epigenome Pipeline for single sample was done."  >> ${oup_log}

