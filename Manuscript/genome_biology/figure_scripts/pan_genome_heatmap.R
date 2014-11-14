#!/usr/bin/env R
library(ggplot2)
library(gridBase)
library(gridExtra)
library(gtable)
library(ggdendro)
library(argparser)
library(reshape2)
library(ape)

parser <- arg.parser("Create a heatmap of the pan-genome distribution")
parser <- add.argument(parser
  ,c("input","tree")
  ,help = c("Tab-delimited file of pan-genome presence / absence data", "Tree of same data as the table file, with identical names.")
  ,short = c("-i","-t")
  ,default = list("",""))

#get all the parameters into usable format
argv <- parse.args(parser)

#data is a tab-delimited table of genome name columns, segment name rows
#binary data indicating the presence / absence of a segment based on the Panseq
#run settings
binaryData <- read.table(file=argv$input, header=TRUE,sep="\t",check.names=TRUE,row.names=1);


#tree of the same data, with the same names on the leaves as column headers for the table
newickTree <- read.tree(file=argv$tree)

#first need to make the tree rooted, binary and ultrametric for use as an hclust 
#object. 
binaryTree <- multi2di(newickTree, random=FALSE)
ultraTree <- compute.brlen(binaryTree, method="Grafen")
hclustTree <- as.hclust(ultraTree)

#extract dendrogram data for plotting
ddata <- dendro_data(hclustTree)

#order of the genomes in the tree
orderOfTree <-ultraTree$tip.label 

#get the order of rows from most "core" to least
coreOrder <- rev(sort(rowSums(binaryData)))

#we want the data under the tree to be in the same order
orderedBinaryData <- binaryData[coreOrder,orderOfTree]

#we want to be able to refer to the rownames as the "id" for the melted data
orderedBinaryData$id <- rownames(binaryData)


#melt the data to long form for ease of ggplot2
#the ids are the rownames, the genome names are the variables, and the actual numeric data is the value
mData <- melt(orderedBinaryData,id.vars=c("id"), value.name="value", variable.name="variable")

#create the pan-genome heatmap, with columns for genomes, and rows for fragments
heatmap <- ggplot(mData, aes(x=variable, y=id)) + geom_raster(size=1, hpad=0, vpad=0, aes(fill=value, width=5)) + scale_fill_continuous(expand=c(0,0), low="white",high="black", breaks=c(0,1), guide="legend", labels=c("Absent","Present")) + coord_equal() + xlab("Genomes") + ylab("Genomic regions")  + theme(
          axis.text.x=element_blank(),
          axis.text.y=element_blank(),
          #axis.ticks=element_blank(),
          #axis.ticks.margin=unit(0,"in"),
          axis.title.x=element_text(size=rel(2)),
          axis.title.y=element_text(size=rel(2)),
          #legend.position="none",
          legend.title=element_blank(),
          legend.background=element_rect(fill="grey"),
          panel.background=element_blank(),
          #panel.border=element_blank(),
          #panel.grid.major=element_blank(),
          #panel.grid.minor=element_blank(),
          plot.background=element_blank()) #top, right, bottom, left

#using the gtable package (http://cran.r-pject.org/web/packages/gtable/index.html)
heatGrob <- ggplotGrob(heatmap) 
#pos=0 adds a row above the current row, default is below
#no matter the removal of the axes and legends, the space on the bottom and left remains for them. There must be a simple solution for this, but unfortunately I could not find it. Instead, the hack of adjusting the bottom and left margins by -4 produce an end result that is the same.
ggTree <- ggplot(segment(ddata)) + geom_segment(aes(x=x, y=y, xend=xend, yend=yend)) + scale_y_continuous(expand = c(0,0),breaks=NULL) + scale_x_discrete(expand = c(0,0),breaks=NULL) +theme(axis.line=element_blank(),
                      axis.text.x=element_blank(),
                      axis.text.y=element_blank(),
                      axis.ticks=element_blank(),
                      axis.ticks.margin=unit(0,"in"),
                      axis.title.x=element_blank(),
                      axis.title.y=element_blank(),
                      legend.position="none",
                      panel.background=element_blank(),
                      panel.border=element_blank(),
                      panel.grid.major=element_blank(),
                      panel.grid.minor=element_blank(),
                      plot.background=element_blank(),
                      plot.margin = unit(c(0,0,-4,-4),"mm")) #top, right, bottom, left

ggTreeGrob <- ggplotGrob(ggTree)
finalImage <- gtable_add_rows(heatGrob, unit(5,"in"), 0)
finalImage <-gtable_add_grob(finalImage, ggTreeGrob, t=1, b=2, l=4)


#this was for debugging the layout of the table rows and columns
# print(ncol(finalImage))
# print(nrow(finalImage))
# finalImage <- gtable_add_grob(finalImage, rectGrob(gp=gpar(fill="red")),t = 1, l=1)
# finalImage <- gtable_add_grob(finalImage, rectGrob(gp=gpar(fill="green")), t = 1, l=2)
# finalImage <- gtable_add_grob(finalImage, rectGrob(gp=gpar(fill="blue")), t = 1, l=3)
# finalImage <- gtable_add_grob(finalImage, rectGrob(gp=gpar(fill="purple")), t = 1, b=2, l=4)
#finalImage <- gtable_add_grob(finalImage, rectGrob(gp=gpar(fill="orange")), t = 1, l=5)

#cannot use ggsave with the multiple grobs needed for the image
#need to go the "traditional" R way
pdf("../panGenomeHeatmap.pdf",width=20, height=20)
grid.draw(finalImage)
dev.off()
