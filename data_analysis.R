#----- Set Up Enviro -----
library(GEOquery)
library(tidyverse)
library(ggplot2)
library(dplyr)
library(DESeq2)         
library(EnhancedVolcano)

gset <- getGEO("GSE5583") # downloads dataset from GEO database

#----- Data Wrangling/Cleaning -----
assay_data <- gset[["GSE5583_series_matrix.txt.gz"]]@assayData[["exprs"]] # expression data
pheno_data <- gset[["GSE5583_series_matrix.txt.gz"]]@phenoData@data # info on samples
feat_data <- gset[["GSE5583_series_matrix.txt.gz"]]@featureData@data # info on genes

# Explore the data
class(assay_data) # shows data type
dim(assay_data) # shows num of rows & columns
str(assay_data) # shows data types within
summary(assay_data) # shows summary stats of numeric columns
head(assay_data) # shows first 6 rows 
any(is.na(assay_data)) # checks for NAs in data

assay_data <- as.data.frame(assay_data)  # converts matrix to data frame
colnames(assay_data)
colnames(assay_data) <- c("WT1", "WT2", "WT3", "KO1", "KO2", "KO3") # renames columns for easier identification of samples
                    

# histogram showing distribution of data
og_hist <- assay_data %>% 
  pivot_longer(cols = WT1:KO3, 
               names_to = "Sample", 
               values_to = "Expression") %>% # pivoted data into longer format so that all of the values are in one column
  ggplot(aes(Expression)) + # create histogram based on 'Expression' 
  geom_histogram(colour = 'black',
                 fill = 'lightblue3', 
                 bins = 50) +
  ggtitle('Original GSET Data') +
  theme_bw()

# normalize data

tdata <- log2(assay_data) 

# histogram showing distribution of normalized data
norm_hist <- tdata %>% 
  pivot_longer(cols = WT1:KO3, 
               names_to = "Sample", 
               values_to = "Expression") %>% 
  ggplot(aes(Expression)) +
  geom_histogram(colour = 'black',
                 fill = 'green4', 
                 bins = 50) +
  ggtitle('Normalized GSET Data') +
  theme_bw()
# did not use this for DEA because DESeq2 normalizes data itself when completing the analysis

#----- DEA with Original Data -----
count_data <- round(assay_data) # DEA requires integers
col_data <- pheno_data %>% select(`Genotype:ch1`) %>% 
  rename('Genotype:ch1' = 'condition') # extract conditions from pheno data
rownames(col_data) <- c("WT1", "WT2", "WT3", "KO1", "KO2", "KO3")

# create DESeq data set
dds <- DESeqDataSetFromMatrix(countData = count_data, # use 'FromMatrix' version of function because data is a df/matrix (not a SEO)
                              colData = col_data, 
                              design = ~ condition)

# perform DEA
dea_ds <- DESeq(dds) # function that performs DEA
dea_results <- dea_ds %>% results(contrast = c('condition',
                                               'HDAC1 knock out', 
                                               'wild type')) # specify condition, numerator, & denominator that you want to compare

dea_results_df <- dea_results %>% as.data.frame() # convert dds to df for downstream functions
gene_names <- feat_data %>% select('GB_ACC', 'Gene Title', 'Gene Symbol') # pull gene names from feature data


dea_fc_hist <- dea_results_df %>% # plot fold change to determine cutoff for significance
  ggplot(aes(log2FoldChange)) +
  geom_histogram(colour = 'black',
                 fill = 'orange', 
                 bins = 50) +
  ggtitle('Log2 Fold Change of DEA') +
  theme_bw()

dea_results_sig <- dea_results_df %>% 
  filter(padj < 0.05 & abs(log2FoldChange) >= 2.0) # filter the results of the DEA for significance


# reorder df so that head = greatest positive FC and tail = greatest negative FC
ranked_genes <- dea_results_sig[order(-dea_results_sig$log2FoldChange), ] 
head(ranked_genes)
tail(ranked_genes)
# write.csv(ranked_genes, 'ranked_genes_df.csv') # output ranked genes df to a csv to include table in presentation
sig_gene_names <- gene_names %>% subset(rownames(gene_names) %in% rownames(ranked_genes)) # collect gene names of significant genes filtered above

# plot results in a volcano plot to visualize which genes fit criteria
dea_results_df %>% EnhancedVolcano(lab = gene_names$`Gene Symbol`, 
                                   x = 'log2FoldChange', 
                                   y = 'padj', 
                                   xlim = c(-10, 10),
                                   title = 'Differential Expression of HDAC1 Knock-Out Mice',
                                   xlab = 'Log2 FC',
                                   ylab = '-Log10 P-ADJ',
                                   pCutoff = 0.05, 
                                   FCcutoff = 2) 

# another volcano plot of same data w slightly different parameters
dea_results_df %>% EnhancedVolcano(lab = gene_names$`Gene Symbol`, 
                                   x = 'log2FoldChange', 
                                   y = 'padj', 
                                   xlim = c(-10, 10),
                                   ylim = c(0, 10), # add limit to y-axis to better show shape of plot
                                   title = 'Zoomed-In DE of HDAC1 KO Mice',
                                   xlab = 'Log2 FC',
                                   ylab = '-Log10 P-ADJ',
                                   pCutoff = 0.05, 
                                   FCcutoff = 2)

