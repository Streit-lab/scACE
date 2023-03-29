#!/usr/bin/env python

## From: https://github.com/dpeerlab/SEACells/blob/main/notebooks/SEACell_domain_adapt.ipynb

# Load libraries
import os
import numpy as np
import pandas as pd
import scanpy as sc
import matplotlib
import matplotlib.pyplot as plt
import seaborn as sns
from SEACells.core import summarize_by_SEACell
import anndata
from scipy.sparse import csr_matrix

# Some plotting aesthetics
sns.set_style('ticks')
matplotlib.rcParams['figure.figsize'] = [4, 4]
matplotlib.rcParams['figure.dpi'] = 100

def parse_args(args=None):
    Description = " "
    Epilog = " "

    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--input', type=str, help="Input path.", metavar='')
    parser.add_argument('-c', '--ncores', type=str, help="Number of CPUs.", metavar='')
    return parser.parse_args(args)

# setting paths interactively
#os.chdir("/Users/hamrude/dev/repos/atac_neural_plate_border/local_test_data")
#plot_path = "./seacell_integration/plots/"
#if not os.path.exists(plot_path):
#    os.mkdir(plot_path)

def compute_distances(df1, df2):
    result = pd.DataFrame(np.zeros((df1.shape[0],df2.shape[0]))).set_index(df1.index)
    result.columns = df2.index

    for mc1, row1 in df1.iterrows():
        for mc2, row2 in df2.iterrows():
            result.loc[mc1, mc2] = np.sqrt(((row1-row2)**2).sum())

    return result

def get_match_ranks(t,k=5):
    #Compute mutually ranked metacell matches.

    arr = t.values.T
    ind = np.argsort(arr, axis=0)[:k].T

    df = pd.DataFrame(t.columns.values[ind])
    df.index = t.index
    
    return df

def MNN(rna_PCs, atac_PCs, k=3):
    #Construct a mapping between RNA and ATAC SEACells, if an RNA SEACell and 
    #ATAC SEACell are mutually in each others' k-nearest neighbors.
    #Nearest neighbors are computed based on distance in transformed PC space,
    #following domain adaption by optimal transport.
    
    # Compute distances between PCs in each data set
    dists = compute_distances(rna_PCs, atac_PCs)
    
    # Find the top k nearest neighbors in each row of the distance matrix
    r1 = get_match_ranks(dists, k)
    r2 = get_match_ranks(dists.T, k)
    # Add edges between samples if they appear in each others top-ranks 

    edges = []
    for index, row in r1.iterrows():
        for nbr in row.values:
            if index in r2.loc[nbr].values:
                edges.append((index, nbr))

    edges = pd.DataFrame(edges)
    edges.columns = ['RNA', 'ATAC']
    return edges

def main(args=None):

    # read in command line arguments
    args = parse_args(args)
    print(args.input)

    # set output paths
    plot_path = "./plots/"
    rds_path = "./rds_files/"
    if not os.path.exists(plot_path):
        os.mkdir(plot_path)
    if not os.path.exists(rds_path):
        os.mkdir(rds_path)

    # Cell type colour map
    cell_type_colors = {'NNE': '#ed5e5f', 
                      'HB': '#A73C52', 
                      'eNPB': '#6B5F88', 
                      'PPR': '#3780B3', 
                      'aPPR': '#3F918C', 
                      'streak': '#47A266',
                      'pPPR': '#53A651', 
                      'NPB': '#6D8470', 
                      'aNPB': '#87638F', 
                      'pNPB': '#A5548D',
                      'eCN': '#C96555', 
                      'dNC': '#ED761C',
                      'eN': '#FF9508', 
                      'NC': '#FFC11A', 
                      'NP': '#FFEE2C', 
                      'pNP': '#EBDA30', 
                      'EE': '#CC9F2C', 
                      'iNP': '#AD6428', 
                      'MB': '#BB614F', 
                      'vFB': '#D77083', 
                      'aNP': '#F37FB8', 
                      'node': '#DA88B3', 
                      'FB': '#B990A6', 
                      'pEpi': '#b3b3b3', 
                      'PGC': '#786D73', 
                      'BI': '#581845', 
                      'meso': '#9792A3', 
                      'endo': '#BBB3CB'
                      }

    ####################    Load data   ####################

    print(os.listdir(args.input))
    ## Read in RNA
    rna_ad = sc.read(args.input + 'AnnData_RNA.h5ad')
    #rna_ad = sc.read("./test_inputs/test_input_AnnData_seacells_processed_for_integration/AnnData_ss8_RNA.h5ad") # ss8 test local
    print(rna_ad)

    # check rna object by running UMAP
    plt.figure(figsize=(8,8))
    sc.pl.umap(rna_ad, color=['scHelper_cell_type'], legend_fontsize=8, palette = cell_type_colors)
    plt.savefig(os.path.join(plot_path, "UMAP_RNA.png"))
    plt.close()

    ## Read in ATAC
    atac_ad = sc.read(args.input + 'AnnData_ATAC.h5ad')
    #atac_ad = sc.read("./test_inputs/test_input_AnnData_seacells_processed_for_integration/AnnData_ss8_ATAC.h5ad") # ss8 test local
    print(atac_ad)

    # check atac object by running UMAP
    plt.figure(figsize=(8,8))
    sc.pl.umap(atac_ad, color=['scHelper_cell_type'], legend_fontsize=8, palette = cell_type_colors)
    plt.savefig(os.path.join(plot_path, "UMAP_ATAC.png"))
    plt.close()

    print("Data read in!")

    ####################    Make combined AnnData object   ####################

    # Annotate the Anndata objects based on their dataset
    atac_ad.obs['Dataset'] = 'ATAC'
    rna_ad.obs['Dataset'] = 'RNA'

    # Identify highly variable genes in RNA object
    sc.pp.highly_variable_genes(rna_ad)

    # Identify list of hvg which are also present in atac object
    hvg = rna_ad.var_names[rna_ad.var['highly_variable']].intersection(atac_ad.var_names)
    print(hvg)

    # Create a combined Anndata object only including hvg
    comb_ad = rna_ad[:, hvg].concatenate(atac_ad[:, hvg])
    print(comb_ad)

    # PCA 
    from sklearn.decomposition import TruncatedSVD
    svd = TruncatedSVD(n_components=30)
    comb_ad.obsm['X_pca'] = svd.fit_transform(comb_ad.X)

    print("Combined AnnData object made!")

    ####################    Run Integration   ####################

    xs = comb_ad[comb_ad.obs['Dataset'] == 'RNA'].obsm['X_pca']
    xt = comb_ad[comb_ad.obs['Dataset'] == 'ATAC'].obsm['X_pca']

    from SEACells.domainadapt import LinearOT

    model = LinearOT(rho=0)
    xs_transformed, xt_transformed = model.fit_transform(xs, xt)
    comb_ad.obsm['X_pca_transformed'] = pd.DataFrame(xs_transformed).append(pd.DataFrame(xt_transformed)).values

    # Save integrated AnnData object
    comb_ad.write(os.path.join(rds_path, 'AnnData_metacells_integrated.h5ad'))

    print("Integration ran!")

    ####################    View Integration   ####################

    sc.pp.neighbors(comb_ad, use_rep='X_pca_transformed', n_neighbors=5)
    sc.tl.umap(comb_ad)

    # UMAP with ATAC or RNA labelled
    plt.figure(figsize=(8,8))
    sc.pl.scatter(comb_ad, basis='umap', color=['Dataset'], frameon=False)
    plt.savefig(os.path.join(plot_path, "UMAP_integrated_modality.png"))
    plt.close()

    # UMAP with scHelper_cell_type labelled
    plt.figure(figsize=(8,8))
    sc.pl.umap(comb_ad, color=['scHelper_cell_type'], legend_fontsize=8, palette = cell_type_colors)
    plt.savefig(os.path.join(plot_path, "UMAP_integrated_celltype.png"))
    plt.close()

    ####################    Mapping ATAC SEACells to RNA SEACells   ####################

    # Mapping ATAC SEACells to RNA SEACellss
    rna_PCs = pd.DataFrame(xs_transformed)
    atac_PCs = pd.DataFrame(xt_transformed)

    rna_PCs.index = rna_ad.obs_names
    atac_PCs.index = atac_ad.obs_names

    mapping = MNN(rna_PCs, atac_PCs)
    mapping.head()

    # Write mapping as csv
    mapping.to_csv(os.path.join(rds_path, 'SEACell_mappings.csv'))

if __name__ == '__main__':
    sys.exit(main())

