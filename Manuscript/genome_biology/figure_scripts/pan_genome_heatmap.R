#!/usr/bin/env R
library(ggplot2)
library(gridBase)
library(gridExtra)
library(gtable)
library(ggdendro)
library(RColorBrewer)
library(argparser)


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



#create the genome size histogram
p <- ggplot(columnData, aes(x = fragments)) + geom_density()
gp <- ggplotGrob(p)


pdf("../panGenomeHeatmap.pdf")
grid.arrange(gp)
dev.off()


