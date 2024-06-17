## Reproducing the analysis of this project
As stated above, different subsets of this project's analysis have been run in different ways. 

To re-run the analysis that utilise the Streit-lab pipelines or NF-core pipelines please see the README files linked in the table above and consult the documentation of the original pipelines. 

To reproduce the analysis performed in the two custom pipelines: NF-downstream_analysis and NF-hichip_downstream, perform the following steps:
1) Clone this repository from Github
2) Ensure Nextflow is installed on the computer or HPC in which the pipeline will be run (HPC or cloud server recommended as computing requirements are high)
3) Download and process the raw data (using the Nextflow hic pipeline for the HiChip or Cellranger for the scATAC-seq data) and change the samplesheets to reflect the correct path to the aligned data. 
[Samplesheet for NF-hichip_downstream input](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-hichip-downstream/samplesheet_validpairs.csv) / [Samplesheet for NF-downstream_analysis input](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/samplesheets/samplesheet_aligned.csv)
4) The bash scripts in the 'run_scripts' folder are how the Nextflow pipelines are triggered. These may need to be edited depending on how modules are loaded in the HPC and to set cache directories for singularity containers and nextflow. 
[Run script for NF-hichip_downstream pipeline](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-hichip-downstream/run_scripts/crick_full.sh) / [Run script for NF-downstream_analysis pipeline](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/run_scripts/crick_full.sh)
5) The run script also specifies a 'profile' which includes platform-specific parameters and paths to reference genomes. A new profile can be created, named and specified in the run script. This [example profile](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/conf/crick_test.config) can be used as a template.
6) Once the pipeline has been adapted to run from a different computer or HPC system, it can be executed by running the run script

## Reusing code from this repository for other projects
The two custom Nextflow pipelines, NF-downstream_analysis and NF-hichip_downstream, can be reused in whole or in part for other projects and analyses. Below is instructions on how the whole pipeline, modules of the pipeline or scripts of the pipeline can be re-used and re-purposed. For more information on what the different steps of these pipelines do and which might be useful for re-purposing see their README docs ([NF-downstream_analysis README](https://github.com/evaham1/atac_neural_plate_border/tree/main/NF-downstream_analysis), [NF-hichip_downstream README](https://github.com/evaham1/atac_neural_plate_border/tree/main/NF-hichip-downstream)). 

### Reusing whole Nextflow pipeline with different input data - NF_hichip-downstream
Despite being made of some generalised components, the whole NF-downstream_analysis pipeline is specific to the data and question of the NPB project, and so it is not recommeded to run these pipelines entirely on different data. 

In contrast, the NF-hichip_downstream pipeline can be used to predict enhancer-gene pairs in any HiChip dataset. To run the pipeline with different data, 3 data inputs need to be changed. 
1) the [samplesheet](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-hichip-downstream/samplesheet_validpairs.csv) should be modified to reflect the different HiChip data in the form of Valid Pairs - this data must have been pre-processed using the NF-core HiC pipeline. 
2) The genome should be adapted to the species of interest by changing the path to the gtf file and genome index file in the [profile config](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-hichip-downstream/conf/crick_full.config). 
3) The 'peaks' path should be a bed file of where ehancers are predicted to be located. In this project the peaks from the scATAC-seq data were used, however bulk peaks, Chip-seq peaks or equivalent can be used. This path is also specified in the [profile config](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-hichip-downstream/conf/crick_full.config).

For more information on what the NF-hichip_downstream pipeline does see the [pipeline's documentation](https://github.com/evaham1/atac_neural_plate_border/tree/main/NF-hichip-downstream).

### Reusing Nextflow modules
Nextflow [modules](https://www.nextflow.io/docs/latest/module.html) are called into the pipeline as processes. The modules used for the NF_hichip-downstream pipeline can be found [here](https://github.com/evaham1/atac_neural_plate_border/tree/main/NF-hichip-downstream/modules/local) and for the NF-downstream_analysis pipeline [here](https://github.com/evaham1/atac_neural_plate_border/tree/main/NF-downstream_analysis/modules/local). These modules can be re-used in other Nextflow pipelines by copying their main.nf file and loading them into a pipeline as a process 
e.g.
```
include {EXTRACT_PROMOTERS} from "$baseDir/modules/local/extract_promoters/main"
``` 
Looking at the main.nf Nextflow script for the module can reveal what the module does and what it expects as input and output, for example see the [module to extract promoters from a gtf](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-hichip-downstream/modules/local/extract_promoters/main.nf). 

Two of the Nextflow modules used in these pipelines are generic in that they run either an [R script](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/modules/local/r/main.nf) or a [python script](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/modules/local/python/main.nf). Please note that both modules expect a tuple as input data - i.e. the data and associated metadata. 

> Note that each Nextflow module is associated with a Docker container,
> this can be seen in the module's main.nf script. These containers 
> overcome dependency issues and make the Nextflow pipeline portable. 
> Some of the containers are from the Docker repository Docker.hub
> whilst others are custom-made, and their Docker scripts can be 
> found in the same folder as the module's main.nf script

### Reusing R and python scripts
The generic R and python modules mentioned above can be read into the Nextflow pipeline together with a specific script like so:
```
include {R as PEAK_CALL} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/ArchR_utilities/ArchR_peak_calling.R", checkIfExists: true) )
```

The custom pipelines in this repository include many R and python scripts that can be found in the 'bin' folder of each pipeline. Most of these scripts are highly generalisable and can be used to analyse any scATAC-seq, scRNA-seq and HiChip data. Most of the scripts contain a list of script options at the top which can be overwritten to adjust parameters or skip parts of the script, these options look like this:
```
# Read in command line opts
option_list <- list(
    make_option(c("-r", "--runtype"), action = "store", type = "character", help = "Specify whether running through through 'nextflow' in order to switch paths"),
    make_option(c("-c", "--cores"), action = "store", type = "integer", help = "Number of CPUs"),
    make_option(c("", "--stage_clust_res"), action = "store", type = "double", help = "clustering resolution for stage data", default = 1),
    make_option(c("", "--full_clust_res"), action = "store", type = "double", help = "clustering resolution for full data", default = 2),
    make_option(c("", "--clustree_stage"), action = "store", type = "logical", help = "whether to run clustree plot on stage data", default = FALSE),
    make_option(c("", "--clustree_full"), action = "store", type = "logical", help = "whether to run clustree plot on full data", default = FALSE),
    )

opt_parser = OptionParser(option_list = option_list)
opt <- parse_args(opt_parser)
if(opt$verbose) print(opt)
```
and can be overwritten in a config file if running the script using the R/python modules in Nextflow pipeline, or they can just be added as arguments if the script is being run from the commandline. 

For more information on each R and python script and what they do see the pipeline's README docs ([NF-downstream_analysis README](https://github.com/evaham1/atac_neural_plate_border/tree/main/NF-downstream_analysis), [NF-hichip_downstream README](https://github.com/evaham1/atac_neural_plate_border/tree/main/NF-hichip-downstream)). 


# NF-downstream_analysis

This folder contains all the code used to perform downstream analysis of scATAC-seq data and scRNA-seq data collected from the chick ectoderm in this project. This code is organised into a custom Nextflow pipeline. Different parts of the pipeline utilise different packages, including: the R packages ArchR (for scATAC-seq analysis), Seurat (for scRNA-seq analysis), Antler (for peak/gene module analysis) and scMEGA (for GRN inference) and the Python package SEACells (for metacell analysis). 

As the pipeline is long, it is divided into sections which can be run independently of each other using switches. These sections are:

* Upstream Processing - creates an ArchR object from aligned scATAC-seq data and filters poor quality cells
* Single Cell Processing - clusters scATAC-seq data, performs peak calling, integrates with scRNA-seq data and performs additional data preparation steps for scMEGA processing
* scMEGA Processing - integrates scATAC-seq and scRNA-seq data and runs scMEGA GRN inference
* Metacell Processing - summarises scATAC-seq and scRNA-seq data as metacells, integrates them and identifies peak modules
* Multiview Processing - visualises metacell assignments on single cells, visualise peak module dynamics, motif analysis

## Upstream Processing ('upstream_processing')
This part of the pipeline must be run before any other analysis. This section creates the ArchR object which allows for easy manipulation of scATAC-seq data, and performs important quality control and filtering steps on this data. 

First, the Cellranger output is combined with the reference genome annotation file (.gtf) and this data is fed into the process PREPROCESSING which runs the R module using the R script [ArchR_preprocessing.R](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/ArchR_preprocessing/ArchR_preprocessing.R). This script builds gene and genome annotations from the UCSC galGal6 genome and the inputted gtf file. It then reads in three cellranger outputs: filtered peak matrix, cell IDs and fragments, and converts them into Arrow files and an ArchR project. These steps (and the reference geome) can be modified, and they loosely follow the [ArchR tutorial](https://www.archrproject.com/bookdown/index.html).

Once the ArchR project has been made, it is passed to a custom Nextflow subworkflow called [FILTERING](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/subworkflows/local/UPSTREAM_PROCESSING/Filtering.nf). Subworkflows allow for pipeline abstraction and ease their organisation. 

1) Filtering full data for doublets
This subworkflow first filters out potential doublets by removing cells that have very high numbers of fragments. As the 5 samples used in the NPB project were sequenced to varying degrees, a sample-specific approach was taken and only cells that had more than 1SD above the mean number of fragments for that sample were removed. This is carried out by the process GLOBAL_FILTER which runs the custom R script [ArchR_global_filtering.R](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/ArchR_preprocessing/ArchR_global_filtering.R). This R script uses ArchR to plot the distribution of fragment counts, nucleosome banding signal and transcription start site enrichment scores for each sample. In the NPB project, only fragment counts were used as a metric to filter cells, however the script can be edited to filter on other QC metrics and/or change the filtering thresholds. 

2) Filtering each sample for poor quality cells
As well as being doublets, cells can be poor quality or dying and therefore should be removed from downstream analysis. Rather than filtering cells using arbitrary thresholds, cells were clustered and then assessed for their distribution of the quality control metrics TSS enrichment and nucleosome banding. If a cluster showed an outlier pattern (i.e. outside the 20-80 percentile range of the clusters in that sample), it was removed. This was run iteratively until no outlier clusters remained. This filtering step was run on each sample individually, so first the process SPLIT_STAGES was run which uses the R script [ArchR_split_stages.R](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/ArchR_utilities/ArchR_split_stages.R) to split the ArchR project by stage into individual ArchR projects. This uses the generic R function [ArchR_SplitbyStage](https://github.com/alexthiery/scHelper/blob/master/R/ArchR_SplitbyStage.R) which is part of the scHelper R package from the Streitlab group. Next, the individual stages were processed in parallel by the process FILTER_CLUSTER_LOOP which uses the R script [ArchR_cluster_filter_loop.R](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/ArchR_preprocessing/ArchR_cluster_filter_loop.R) which can be modified. 

3) Combining filtering steps
Finally, the results of these two filtering steps are combined. The first filtering step was performed on the full dataset, whilst the first and second step was performed on the individual stages. Therefore the full data still needs to be filtered for the second filtering step. To do this, the output of the second filtering step is collected so all the samples are combined into one channel, and then they are fed into the process FILTER_FULL which runs the R script [ArchR_filter_full_data.R](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/ArchR_preprocessing/ArchR_filter_full_data.R) which uses the cell IDs of the ArchR sample projects to filter the full dataset ArchR project. 

![plot](preprocess_filtering.png)

### Re-using the steps in this workflow
We believe that our filtering approach can separate poor quality and doublet cells from good datapoints as it 1) does not rely on arbitary quality metric thresholds, 2) accounts for sequencing depth differences between samples and 3) utilises the assumption that cells of a similar quality cluster together. Our Nextflow workflow can be reused either in whole, by simply changing the input data and genome, or in part by utilising the R scripts directly and adjusting them as required. 

## Single Cell Processing ('sc_processing')
This part of the pipeline processes the scATAC-seq data at a single cell level by clustering, calling peaks and integrating with scRNA-seq data. This section of the pipeline results in an ArchR object with the full data and an ArchR object for each sample (in the case of the NPB project, each sample corresponds to a developmental stage). All of these ArchR objects have the same peak information, cell state labels and integrated gene counts. Finally, the full dataset is further processed to add latent time information from scRNA-seq data so it can be used for network inference. 

First, the full dataset is clustered, peaks are called and the data is integrated with scRNA-seq data. Clustering is performed using the process CLUSTER_FULL or CLUSTER_STAGES which calls the R script [ArchR_clustering.R](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/ArchR_utilities/ArchR_clustering.R) and peak calling is performed using the process PEAK_CALL which calls the R script [ArchR_peak_calling.R](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/ArchR_utilities/ArchR_peak_calling.R). During the integration step, the full ArchR object is also processed to calculate peak to gene linkages based on co-occurance. The integration and p2g linkage analysis is run by the process INTEGRATE which runs the R script [ArchR_constrained_integration_coaccessibility.R](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/Integration/ArchR_constrained_integration_coaccessibility.R). All of these steps are performed using ArchR functions. In parallel, the sample dataset is also clustered so that they can be visualised by their invididual UMAP embeddings. Peak calling on just one sample would result in a different set of peaks than peak calling across the whole dataset. To ensure that all data objects have the same peak set and integration results, peak calling and integration was performed on the full dataset and then the resulting information was transferred onto the sample ArchR objects. 

![plot](sc_processing.png)

At the end of this section of the pipeline, some additional processing steps are carried out on the full data object to prepare it for network inference using scMEGA. These steps involve transferring latent time information from scRNA-seq data onto the scATAC-seq data. As latent time values are not assigned to every cell in the dataset, the scATAC-seq data is then subsetted to only include cells in the latent time trajectory and re-clustered. 

![plot](sc_processing_fulldata.png)

### Re-using the steps in this workflow
Each step in this section of the pipeline runs a generic R script which can be re-used for other scATAC-seq analysis. [14 R scripts](https://github.com/evaham1/atac_neural_plate_border/tree/main/NF-downstream_analysis/bin/ArchR_utilities) have been created which run various steps of scATAC-seq analysis using the ArchR package. These scripts process the data by clustering, peak calling and integrating, but also create extra visualisations and QC checks using custom functions from the [scHelper package](https://github.com/alexthiery/scHelper). At the top of each R script are a list of script options which can be overwritten externally, either in a config file if running through a Nextflow pipeline or in the bash command if running the R script on the command line. As many arguments such as clustering resolution have been abstracted out in this way, these R scripts can be run for any analysis without modification. 

## scMEGA Processing (mega_processing)
This part of the pipeline uses modified functions from the R package [scMEGA](https://github.com/CostaLab/scMEGA) to infer a GRN of placodal development. 

First, the ArchR full data object with latent time is converted to a Seurat object, as this is the input format expected by scMEGA. This is performed using the generic R script [ArchR_to_seurat.R](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/data_conversion/ArchR_to_seurat.R) called using the process ARCHR_TO_SEURAT. As the RNA seurat dataset contains an extra stage that is not present in the scATAC-seq dataset, the developmental stage HH4 is removed using the process REMOVE_HH4 which calls the R script [remove_HH4_RNA_data.R](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/data_conversion/remove_HH4_RNA_data.R). The scRNA-seq and scATAC-seq data are then integrated using the process MEGA_PAIRING_CHROMVAR which calls the R script [MEGA_make_multiome.R"](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/scMEGA/MEGA_make_multiome.R). This integration actually uses the same cell-cell pairings as in the previous integration performed in the 'sc_processing' section of the pipeline, however it is re-performed here so that the data is in a Seurat format rather than ArchR. 

As well as creating a pseudo-multiome Seurat object using previously calculated cell-cell pairings, the MEGA_PAIRING_CHROMVAR also runs [ChromVar analysis](https://greenleaflab.github.io/chromVAR/articles/Introduction.html#:~:text=chromVAR%20is%20an%20R%20package,annotations%20such%20as%20motif%20positions.), which calculates the activity of each TF based on the accessibility of its targets in each cell. This Seurat object is then combined with previously calculated peak-to-gene linkages, which were calculated using the ArchR package in the 'sc_processing' section of the pipeline. These data are used to infer a GRN using the process MEGA_GRNI which calls the R script [MEGA_GRNi.R](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/scMEGA/MEGA_GRNi.R), and then visualise the network using the process MEGA_GRN_VIS calling the [MEGA_GRN_vis.R](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/scMEGA/MEGA_GRN_vis.R) R script. The visualisation script also creates csv files detailing the interactions and metadata about each node in the network which can be easily imported into other network visualisation softwares such as [Cytoscape](https://cytoscape.org/). 

![plot](mega_processing.png)

### Re-using the steps in this workflow
This section of the pipeline converts data between ArchR and Seurat, several generalised R scripts which perform data conversion between different package ecosystems can be found in the [data_conversion folder](https://github.com/evaham1/atac_neural_plate_border/tree/main/NF-downstream_analysis/bin/data_conversion). The [R script used to remove the HH4 sample](https://github.com/evaham1/atac_neural_plate_border/blob/main/NF-downstream_analysis/bin/data_conversion/remove_HH4_RNA_data.R) can also be edited to remove any sample from Seurat data. 

The GRN section of the pipeline was run using [three custom R scripts](https://github.com/evaham1/atac_neural_plate_border/tree/main/NF-downstream_analysis/bin/scMEGA) which include modified scMEGA functions to allow for more control over visualisation and GRN inference parameters. These R scripts can be explored and adapted for other datasets. 



