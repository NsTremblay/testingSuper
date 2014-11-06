#!/usr/bin/env 
library(ggplot2)
library(argparser)
library(RColorBrewer)

parser <- arg.parser("Create a histogram for pan-genome distribution")
parser <- add.argument(parser
  ,c("input") 
  ,help = c("Tab-delimited file of pan-genome presence / absence data"))

#get all the parameters into usable format
argv <- parse.args(parser)

binaryData <- read.table(file=argv$input, header=TRUE,sep="\t",check.names=TRUE,row.names=1);

name <- names(binaryData)
colsums <- colSums(binaryData)
rowsums <- rowSums(binaryData)
approxGenomeSize <- colsums * 1000
genomeSizeHistoData <- data.frame(name,approxGenomeSize)
panGenomeHistoData <- data.frame(rowsums)

fillColor <- "#330000"

h <- ggplot(data = genomeSizeHistoData
           ,aes(x = approxGenomeSize))
genomeSize <- h + geom_histogram(binwidth =100000, fill=fillColor, colour="black") + scale_x_continuous("Genome Size (Mbp)") + scale_y_continuous("Frequency")
ggsave(filename="../genomeSize.pdf", plot=genomeSize)

panH <- ggplot(data = panGenomeHistoData, aes(x = rowsums))
panSize <- panH + geom_histogram(binwidth = 100, fill=fillColor, colour="black") + scale_x_continuous("No. of Genomes") + scale_y_continuous("Frequency")
ggsave(filename="../panGenomeSize.pdf", plot=panSize)
