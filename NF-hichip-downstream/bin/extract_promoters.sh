#!/bin/bash

# Specify inputs
gtf_file="$1"
output_file="$2"

# Extracts all genes

# Changes chromosome names to 'chr1'
# Extracts gene name or if there is no gene name, gene ID
awk -F'\t' '$3 ~ /gene/ {
    if ($7 == "+") {
        $5 = $4
        $4 = $4 - 2000
    } else if ($7 == "-") {
        $4 = $5
        $5 = $5 + 2000
    }
    # Extract gene_id and gene_name values within quotations
    split($9, a, "\"");
    gene_id=a[2];
         if (a[10]=="") { 
             gene_name=gene_id;
         } else { 
             gene_name=a[6];
         }
    # Create output with selected columns and added gene_id and gene_name variables
    output = "chr"$1 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" gene_id "\t" gene_name
    print output
}' "$gtf_file" > "$output_file"



# # Removes header lines starting with "#"
# # Only keeps lines with "gene" in the 3rd column
# # Splits the 9th column by ";" and then by "\""
# # Prints the 1st, 4th, 5th, 9th, 10th, and 7th columns (Chr, start, end, gene_id, gene_name, strand)
# # The gene name is the 6th column if it exists, otherwise it is the gene id
# # Chromosome names are prepended with "chr"
# sed '/^#/d' "$gtf_file" \
# | awk -F "\t" '{
#     if ($3=="gene") {
#         split($9, a, "\"");
#         gene_id=a[2];
#         chr="chr"$1
#         if (a[10]=="") { 
#             gene_name=gene_id;
#         } else { 
#             gene_name=a[6];
#         } 
        
#     print chr"\t"$4-1"\t"$5"\t"gene_id"\t"gene_name"\t"$7;
#   }
# }' \
# > "$output_file"