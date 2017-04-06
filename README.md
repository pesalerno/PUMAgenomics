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



####3. Estimating sequencing error and optimizing stacks parameters 
This is following the Mastretta-yanes et al paper. 

First, you need to run several iterations of the parameters in denovo_map in order to explore parameter space with the R code of Mastretta-Yanes. You only need to run these analyses with the intra- and inter- library replicates. 



Permutations | -m | -M | -n | --max_locus_stacks 
------------ | ------------- | ------------ | ------------- | ------------ |
a | 3 | 2 | 2 | 3 | 
b | 5 | 2 | 2 | 3 |
c | 7 | 2 | 2 | 3 | 
d | 3 | 4 | 2 | 3 |
e | 3 | 6 | 2 | 3 |
f | 3 | 8 | 2 | 3 |
g | 3 | 2 | 4 | 3 |
h | 3 | 2 | 6 | 3 |
i | 3 | 2 | 8 | 3 |
j | 3 | 2 | 2 | 4 |
k | 3 | 2 | 2 | 5 |


**NOTE**: large -M values greatly increases computational time. 

	>>add code for loading into mysql database
	
	>>add info for R code once it's figured out

####4. Genotyping

After you find your error rate and estimate the best parameter settings, you run your entire dataset with the optimal parameters. 

	>>add code for denovo_map.pl

After genotyping, re-run dataset using ***rxstacks***

	>>add code for rxstacks

When you are done, use minimum filter settings in **Stacks** in order to get the most complete matrix to LATER filter in plink. 

	>>add code for populations

####5. Post-processing of SNP matrix

Using [PLINK](http://pngu.mgh.harvard.edu/~purcell/plink/summary.shtml), we filter our dataset in several steps.

First, filter out loci with too much missing data:

	./plink --file input-name --geno 0.5 --recode --out output-filename --noweb

Second, filter out individuals with too much missing data:

	./plink --file input-filename --mind 0.5 --recode --out output-filename --noweb
	
Third, filter out minimum allele frequency:

	./plink --file input-filename --maf 0.01 --recode --out output-filename --noweb
 