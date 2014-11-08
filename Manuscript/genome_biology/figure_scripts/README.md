# Data generation

Panseq commit d67bca1ac6ba35dd43ef59c3260c3e89828e356a run with the file in this directory superphy.batch, which contains the following settings:

    queryDirectory  /home/chad/superphy_data/
    baseDirectory   /home/chad/panseq/output/superphy/
    numberOfCores   23
    mummerDirectory /usr/bin/
    blastDirectory  /usr/bin/
    minimumNovelRegionSize  1000
    muscleExecutable    /usr/bin/muscle
    fragmentationSize   1000
    percentIdentityCutoff   90
    coreGenomeThreshold 1633
    runMode     pan
    storeAlleles    1
    nameOrId    name
    overwrite   1
    allelesToKeep   1
    maxNumberResultsInMemory    1600

# SNP tree building

The snp.phylip alignment from the above Panseq run was converted into a fasta alignment via the script phylip_to_fasta.pl and the command:

    perl phylip_to_fasta.pl snp.phylip > snp.fasta


The fasta alignment was then used in Clearcut v.1.0.9 to create a tree via the following command:

    clearcut -a -D -k --in snp.fasta --out=clearcut_snp.tre

The tree names were then converted from the numerical 1-2324 values to their corresponding names in the phylip_name_conversionl.txt file with the Panseq script treeNumberToName.pl with the command:

    treeNumberToName.pl clearcut_snp.tre phylip_name_conversion.txt > clearcut_snp_name.tre


