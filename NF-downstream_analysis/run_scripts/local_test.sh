#!/bin/bash

nextflow run ./main.nf \
--outdir ./output/ \
-profile local_test \
-resume