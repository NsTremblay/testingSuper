#!/usr/bin/env R
library(ggplot2)
library(ggdendro)
library(RColorBrewer)
library(argparser)
library(fastcluster)


parser <- arg.parser("Create a heatmap of the pan-genome distribution")
parser <- add.argument(parser
  ,c("input")
  ,help = c("Tab-delimited file of pan-genome presence / absence data")
  ,short = c("-i")
  ,default = list(""))

#get all the parameters into usable format
argv <- parse.args(parser)

#data is a tab-delimited table of genome name columns, segment name rows
#binary data indicating the presence / absence of a segment based on the Panseq
#run settings
binaryData <- read.table(file=argv$input, header=TRUE,sep="\t",check.names=TRUE,row.names=1);

columnData <- data.frame(fragments = rownames(binaryData), genomes = rep(colnames(binaryData), each = nrow(binaryData)))


hc <- hclust.vector(binaryData, method="ward", metric="euclidean")
hcdata <-dendro_data(hc, type = "rectangle")

#create the genome size histogram
panHeatMap <- ggplot() + theme_bw() + geom_segment(data=segment(hcdata), aes(x=x, y=y, xend=xend, yend=yend))


ggsave(filename="../panGenomeHeatmap.pdf", plot=panHeatMap)


