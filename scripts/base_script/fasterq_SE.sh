conda activate pandas

echo '$sample $R $srr $thread ${fq_ext}' $sample $R $srr $thread ${fq_ext}
python ~/script/rna-pipe/make_fasterq_SE.py $sample $R $srr $thread ${fq_ext}

conda activate RNA-seq-py3.10

fqd=${sample}_fqd.sh
agg=${sample}_agg.sh

. $fqd

if [[ -f "${agg}" ]]; then
	. $agg
fi

