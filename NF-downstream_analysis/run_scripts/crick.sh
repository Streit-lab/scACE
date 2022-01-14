#!/bin/bash
#SBATCH --job-name=atac-NPB
#SBATCH -t 72:00:00
#SBATCH --mail-type=ALL,ARRAY_TASKS
#SBATCH --mail-user=eva.hamrud@crick.ac.uk

export TERM=xterm

## LOAD REQUIRED MODULES
ml purge
ml Nextflow/20.07.1
ml Singularity/3.4.2
ml Graphviz

export NXF_VER=20.07.1

nextflow run ./main.nf \
--input ./samplesheet.csv \
--outdir ./output/ \
-profile crick \
-resume