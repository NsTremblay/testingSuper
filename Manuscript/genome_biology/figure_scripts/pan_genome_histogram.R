#!/usr/bin/env R
library(ggplot2)
library(argparser)
library(RColorBrewer)

parser <- arg.parser("Create a histogram for pan-genome distribution")
parser <- add.argument(parser
  ,c("input", "--fragmentSize")
  ,help = c("Tab-delimited file of pan-genome presence / absence data", "The size of the fragments that each binary value denotes")
  ,short = c("-i","-f")
  ,default = list("", 1000))

#get all the parameters into usable format
argv <- parse.args(parser)


#data is a tab-delimited table of genome name columns, segment name rows
#binary data indicating the presence / absence of a segment based on the Panseq
#run settings, where each fragment is of argv$fragmentSize
binaryData <- read.table(file=argv$input, header=TRUE,sep="\t",check.names=TRUE,row.names=1);

#for the histograms, the column sums are the number of pan-genome fragments that
#each genome was found to have the given Panseq settings. 
#the approximate genome size is taken by multiplying the number of fragments by
#the size of the fragments
#the rowsums are the number of genomes that each fragment was found in at the 
#given Panseq settings
colsums <- colSums(binaryData)
rowsums <- rowSums(binaryData)
panGenoneSize <- length(rowsums[rowsums <= 100])
print(panGenoneSize)
q()
approxGenomeSize <- colsums * as.numeric(argv$fragmentSize)
genomeSizeHistoData <- data.frame(approxGenomeSize)
panGenomeHistoData <- data.frame(rowsums)


#from (http://www.colourlovers.com/lover/Monokai/colors)
fillColor <- "#524f52"
lineColor <- "#2c2c2a"

#create the genome size histogram
h <- ggplot(data = genomeSizeHistoData
           ,aes(x = approxGenomeSize))
genomeSize <- h + geom_histogram(binwidth =100000, fill=fillColor, colour=lineColor) + scale_x_continuous("Genome Size (Mbp)") + scale_y_continuous("Frequency") + theme_bw()
#ggsave(filename="../genomeSize.pdf", plot=genomeSize)


#create the pan-genome distribution histogram
panH <- ggplot(data = panGenomeHistoData, aes(x = rowsums))
panSize <- panH + geom_histogram(binwidth = 100, fill=fillColor, colour=lineColor) + scale_x_continuous("No. of Genomes") + scale_y_continuous("Frequency") + theme_bw()

#ggsave(filename="../panGenomeSize.pdf", plot=panSize)
