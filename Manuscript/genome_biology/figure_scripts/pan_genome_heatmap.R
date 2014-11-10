#!/usr/bin/env R
library(ggplot2)
library(gridBase)
library(gridExtra)
library(gtable)
library(ggdendro)
library(RColorBrewer)
library(argparser)
library(reshape2)


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

rNames <- rownames(binaryData)
cNames <- colnames(binaryData)

#we want to be able to refer to the rownames as the "id" for the melted data
binaryData$id <- rownames(binaryData)
#melt the data to long form for ease of ggplot2
#the ids are the rownames, the genome names are the variables, and the actual numeric data is the value
mData <- melt(binaryData,id.vars=c("id"), value.name="value", variable.name="variable")

#create the pan-genome heatmap, with columns for genomes, and rows for fragments
#create a mapping for values and colours (this will allow the legend to use these)
#values, rather than a continuous gradient

heatmap <- ggplot(mData, aes(x=variable, y=id)) + geom_raster(aes(fill=value, width=5)) + scale_fill_continuous(low="white",high="black", breaks=c(0,1), guide="legend") + scale_x_discrete(expand=c(0,0),labels=c("")) + scale_y_discrete(expand=c(0,0),labels=c(""))

#using the gtable package (http://cran.r-project.org/web/packages/gtable/index.html)
#add a row to the heatmap for the dendrogram
finalImage <- ggplotGrob(heatmap)
#pos=0 adds a row above the current row, default is below
finalImage <- gtable_add_rows(finalImage, unit(2,"in"), pos=0)
finalImage <- gtable_add_grob(finalImage, rectGrob(), t=1, l=4, b=1, r=4)

#cannot use ggsave with the multiple grobs needed for the image
#need to go the "traditional" R way
pdf("../panGenomeHeatmap.pdf",width=20, height=20)
grid.arrange(finalImage)
dev.off()
