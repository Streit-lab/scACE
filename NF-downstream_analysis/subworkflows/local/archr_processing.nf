#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include {EDIT_GTF} from "$baseDir/modules/local/edit_gtf/main"

include {R as PREPROCESS} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/ArchR_preprocessing/ArchR_preprocessing.R", checkIfExists: true) )
include {R as DOUBLETS} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/ArchR_preprocessing/ArchR_doublets.R", checkIfExists: true) )
include {R as FILTER} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/ArchR_preprocessing/ArchR_filtering.R", checkIfExists: true) )
include {R as DOUBLETS_FILTERED} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/ArchR_preprocessing/ArchR_doublets.R", checkIfExists: true) )

include {R as CLUSTER_PREFILTER} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/ArchR_preprocessing/ArchR_clustering.R", checkIfExists: true) )
include {R as CLUSTER_POSTFILTER} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/ArchR_preprocessing/ArchR_clustering.R", checkIfExists: true) )
include {R as CLUSTER_POSTFILTER_TWICE} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/ArchR_preprocessing/ArchR_clustering.R", checkIfExists: true) )

include {R as FILTER_CLUSTERS_1} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/ArchR_preprocessing/ArchR_filter_clusters.R", checkIfExists: true) )
include {R as FILTER_CLUSTERS_2} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/ArchR_preprocessing/ArchR_filter_clusters.R", checkIfExists: true) )

include {R as GENE_SCORES} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/ArchR_preprocessing/ArchR_gene_scores.R", checkIfExists: true) )


workflow PROCESSING {
    take:
    input

    main:
    input // [[meta], [cellranger_output, galgal_reference]]
        .set {ch_input}

    EDIT_GTF ( input ) //edits the gtf file to add 'chr' to chromosome names

    EDIT_GTF.out 
        .combine(ch_input) //[[meta], temp.gtf, [meta], cellranger_output, galgal_reference]]
        .map{[it[0], it[[1]] + it[3]]} //[[meta], [temp.gtf, cellranger_output, galgal_reference]]
        .set {ch_input_modified} // ch_metadata: [[meta], [cellranger_output, gtf]]

    // creates arrow files and ArchR project filtered with generous thresholds
    PREPROCESS( ch_input_modified )
    // plots whole sample QC metrics (+ add filtering?)
    FILTER( PREPROCESS.out )

    // iterative clustering and filtering poor quality clusters
    CLUSTER_PREFILTER( FILTER.out )
    FILTER_CLUSTERS_1( CLUSTER_PREFILTER.out ) // filtering round 1
    CLUSTER_POSTFILTER( FILTER_CLUSTERS_1.out )
    FILTER_CLUSTERS_2( CLUSTER_POSTFILTER.out ) // filtering round 2
    CLUSTER_POSTFILTER_TWICE( FILTER_CLUSTERS_2.out )
    
    DOUBLETS_FILTERED( FILTER_CLUSTERS_2.out ) // see if adding doublet scores after filtering any better

    // plots using gene scores
    GENE_SCORES( CLUSTER_POSTFILTER_TWICE.out )

    // extract rds objects
      CLUSTER_POSTFILTER_TWICE.out //[[sample_id:NF-scATACseq_alignment_out], [../ArchRLogs, ../Rplots.pdf, ../rds_files]]
        .map {row -> [row[0], row[1].findAll { it =~ ".*rds_files" }]} //[[sample_id:NF-scATACseq_alignment_out], [../rds_files]]
        .flatMap {it[1][0].listFiles()}
        .map { row -> [[sample_id:row.name.replaceFirst(~/_[^_]+$/, '')], row] }
        //.view() //[[sample_id:FullData], /rds_files/FullData_Save-ArchR]
        .set {output_ch}

    //emit full filtered and clustered dataset:
    emit:
    output = output_ch
}