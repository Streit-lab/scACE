process EDIT_VALIDPAIRS {

    conda "conda-forge::sed=4.7"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ubuntu:20.04' :
        'ubuntu:20.04' }"

    input:
    tuple val(meta), path('input/*')

    output:
    tuple val(meta), file('*')       , emit: outs

    shell:
    '''
    # Print out input file name
    basename ./input/*

    # Rename input file to .txt
    cp ./input/* input.txt

    # Split the input file into smaller chunks
    split -l 1000000 input.txt input_part

    # Edit the second and fifth column of each chunk to add 'chr' to the chromosome name
    for file in input_part*; do
        awk 'BEGIN{FS=OFS="\t"}{$2="chr"$2;$5="chr"$5}1' "${file}" > "${file}.edited" &
    done

    # Wait for all editing jobs to finish
    wait

    # Concatenate the edited chunks into a single output file
    cat input_part*.edited > "edited_ValidPairs.txt"

    # Remove the intermediate files
    rm input.txt input_part*

    # Remove the input folder
    rm -r input

    # Convert the output file to tab-delimited format
    sed -i 's/ /\t/g' "edited_ValidPairs.txt"
    '''
}

    

