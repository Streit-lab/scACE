#!/usr/bin/env nextflow
nextflow.enable.dsl = 2

include {R as PREPROCESSING} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/1_preprocessing.R", checkIfExists: true) )
include {R as FILTERING} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/2_filtering.R", checkIfExists: true) )
include {R as GENE_ACTIVITY} from "$baseDir/modules/local/r/main"               addParams(script: file("$baseDir/bin/3_gene_activity.R", checkIfExists: true) )


workflow PROCESSING {
    take:
    input

    main:
    input
        .set { ch_fragments }

    PREPROCESSING( input )

    ch_fragments
        .combine( PREPROCESSING.out )
        .map{[it[0], it[1] + it[3]]}
        .set { ch_input }
    FILTERING( ch_input )

    ch_fragments
        .combine( FILTERING.out )
        .map{[it[0], it[1] + it[3]]}
        .set { ch_input }
    GENE_ACTIVITY( ch_input )

    emit:
    signac_predicted_gex = GENE_ACTIVITY.out
}
