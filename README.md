# PUMAgenomics

First, we start out generating our [markdown](https://en.wikipedia.org/wiki/Markdown) document with any available program. I use [MOU](http://25.io/mou/) which is great since it live updates your document based on your code, so it's super easy for learning, but I think it's only for mac. 


To begin editing this and other documents in the repository, first navigate to the folder where you want to "clone" this repository to, then initialize a repository and clone the repository:

	cd GITHUB
	git init
	git clone https://github.com/pesalerno/PUMAgenomics

A general description on how to collaborate on github can be found [here](http://code.tutsplus.com/tutorials/how-to-collaborate-on-github--net-34267).


Now we can begin with the workflow. 

####1. Demultiplexing in stacks
Let's have a code that we share for cleaning the data with ***process_radtags***. Are we all using default settings?

	process_radtags -f /path/to/file/sequence.fastq -b /path/to/file/barcodes-names.txt -o /path/output-folder -c -q -r -D -e nlaIII -i fastq

####2. Filtering  PCR duplicates
This will be done using Kelly's [program](https://github.com/kellyp2738/RADseqDuplicateFiltering) which was designed for our  exact same barcodes. 

####3. Exploratory genotyping and error estimation
This is following the MAstretta-yanes et al paper. Code to be found/written! 

####4. Genotyping

####5. Post-processing of SNP matrix

This will be done using the program [PLINK](http://pngu.mgh.harvard.edu/~purcell/plink/summary.shtml). 
 