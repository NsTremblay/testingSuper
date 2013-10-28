library(ape)
library(circular)

newickTree <- read.tree(file="/home/chad/workspace/computational_platform/Phylogeny/NewickTrees/heatmap_tree")

rootedTree <- chronopl(newickTree,0, node="root",age.min = 0, S=1,age.max = 1, tol = 1e-8,CV = FALSE, eval.max = 500, iter.max = 500)

hc <- as.hclust(newickTree)
dend <- as.dendrogram(newickTree)
plot(dend,horiz=TRUE)