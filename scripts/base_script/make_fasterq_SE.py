import pandas as pd
import sys
import subprocess
import os
import re
from collections import defaultdict
import random

args = sys.argv
sample=args[1]
R=args[2]
srr=args[3]
thread=args[4]
fq_ext=args[5]

srcs = " ".join([i for i in srr.split(",")])

fqd_file = f'./{sample}_fqd.sh'
agg_file = f'./{sample}_agg.sh'

if len(srcs.split(" "))==1:
    with open(fqd_file, 'w') as f1:
        fqd = f'prefetch {srcs} && fasterq-dump {srcs} -O ./ -e {thread} && rm -r {srcs} && mv {srcs}.fastq {sample}.{fq_ext} && gzip -f {sample}.{fq_ext}'
        f1.write(f"{fqd}\n")
else :
    with open(fqd_file, 'w') as f1, open(agg_file, 'w') as f2 :
        fqd = f'prefetch {srcs} && fasterq-dump {srcs} -O ./ -e {thread} && rm -r {srcs}'
        f1.write(f"{fqd}\n")
        s = " ".join([f"{i}.fastq" for i in srcs.split(" ")])
        agg = f'cat {s} | gzip -c > {sample}.{fq_ext}.gz && rm {s}'
        f2.write(f"{agg}\n")
            
