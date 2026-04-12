conda activate pandas

python ~/script/rna-pipe/make_fasterq_PE2.py $sample $R1 $R2 $srr $thread ${fq_ext}

conda activate RNA-seq-py3.10

fqd=${sample}_fqd.sh
agg=${sample}_agg.sh
pair=${sample}_pair.sh
gzip=${sample}_gzip.sh

. $fqd

if [[ -f "${agg}" ]]; then
	xargs -I CMD -P $thread bash -c CMD < ${agg} &&
	. $pair &&
	xargs -I CMD -P $thread bash -c CMD < ${gzip}
fi

