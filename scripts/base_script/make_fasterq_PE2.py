import pandas as pd
import sys
import subprocess
import os
import re
from collections import defaultdict
import random

args = sys.argv
sample=args[1]
R1=args[2]
R2=args[3]
srr=args[4]
thread=args[5]
fq_ext=args[6]

srcs = " ".join([i for i in srr.split(",")])

fqd_file = f'./{sample}_fqd.sh'
agg_file = f'./{sample}_agg.sh'
pair_file = f'./{sample}_pair.sh'
gzip_file = f'./{sample}_gzip.sh'

if len(srcs.split(" "))==1:
    with open(fqd_file, 'w') as f1:
        fqd = f'prefetch {srcs} && fasterq-dump {srcs} -O ./ -e {thread}  && rm -r {srcs}  && mv {srcs}_1.fastq {R1}.{fq_ext} && gzip -f {R1}.{fq_ext} && mv {srcs}_2.fastq {R2}.{fq_ext} && gzip -f {R2}.{fq_ext}'
        f1.write(f"{fqd}\n")
else :
    with open(fqd_file, 'w') as f1, open(agg_file, 'w') as f2, open(pair_file, 'w') as f3, open(gzip_file, 'w') as f4:
        fqd = f'prefetch {srcs} && fasterq-dump {srcs} -O ./ -e {thread} && rm -r {srcs}'
        f1.write(f"{fqd}\n")
        for r in [1,2] :
            s = " ".join([f"{i}_{r}.fastq" for i in srcs.split(" ")])
            agg = f'cat {s} > pre_{sample}.R{r}.fq && rm {s}'
            f2.write(f"{agg}\n")
            
        pair = f"fastq_pair -t 100000000 pre_{sample}.R1.fq pre_{sample}.R2.fq && rm pre_{sample}.R1.fq pre_{sample}.R2.fq && mv pre_{sample}.R1.fq.paired.fq {R1}.{fq_ext} && mv pre_{sample}.R2.fq.paired.fq {R2}.{fq_ext}"
    
        f3.write(f"{pair}\n")
        gzip_cmd = f"gzip -f {R1}.{fq_ext} && gzip -f {R2}.{fq_ext}"
        f4.write(f"{gzip_cmd}\n")

