PUMAgenomics
======

First, we start out generating our [markdown](https://en.wikipedia.org/wiki/Markdown) document with any available program. I use [MOU](http://25.io/mou/) which is great since it live updates your document based on your code, so it's super easy for learning, but I think it's only for mac. 


To begin editing this and other documents in the repository, first navigate to the folder where you want to "clone" this repository to, then initialize a repository and clone the repository:

	cd GITHUB
	git init
	git clone https://github.com/pesalerno/PUMAgenomics

A general description on how to collaborate on github can be found [here](http://code.tutsplus.com/tutorials/how-to-collaborate-on-github--net-34267).

Github for ongoing collaborations
-----

I made a handy-dandy short protocol on some practices for easy git collaborating that can be found [here](https://github.com/pesalerno/PUMAgenomics/blob/master/git-collaborating-protocol.md). 


 

Demultiplexing in stacks
-----

Let's have a code that we share for cleaning the data with ***process_radtags***. Are we all using default settings?

	process_radtags -f /path/to/file/sequence.fastq -b /path/to/file/barcodes-names.txt -o /path/output-folder -c -q -r -D -e nlaIII -i fastq



Estimating sequencing error and optimizing stacks parameters 
-----

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

Genotyping
-------

After you find your error rate and estimate the best parameter settings, you run your entire dataset with the optimal parameters. 

	>>denovo_map.pl 
	#!/bin/bash
        #SBATCH --cluster specific info

        mkdir /path/to/denovomap_out

        denovo_map.pl -T 16 -m 5 -M 2 -n 2 -S -b 2 -X "ustacks:--max_locus_stacks [3]" -o /path/to/denovomap_out/ \
        -s /path/to/rad_tags/filename.fq \ 
        -s /path/to/rad_tags/filename.fq \
        -s /path/to/rad_tags/filename.fq \
        -s /path/to/rad_tags/filename.fq 

After genotyping, re-run dataset using ***rxstacks***

	>>rxstacks
	#!/bin/bash
	#SBATCH cluster specific information 

        mkdir /path/to/rxstacks-out
        rxstacks -b 2 -P /path/to/denovomap_out -o /path/to/rxstacks-out --conf_filter --prune_haplo --model_type bounded --bound_high 0.1 --lnl_lim -10.0 -t 8

Need to re-run cstacks and sstacks portion of stacks pipeline. 

Exporting SNP matrix in **populations** (STACKS) using minimal filtering.
------

When you are done, use minimum filter settings in **Stacks** in order to get the most complete matrix to LATER filter in plink. 

	>>populations 
	#!/bin/bash
	#SBATCH cluster specific information 

	populations -b 2 -P /project/wildgen/rgagne/combine/populations/pop-comb-c/ -M /project/wildgen/rgagne/combine/populations/pop-map-combine -fstats -k -p 1 -r 0.2  -t 8 --structure --genepop --vcf --plink --write_random_snp


Post-processing of SNP matrix
-------

Using [PLINK](http://pngu.mgh.harvard.edu/~purcell/plink/summary.shtml), we filter our dataset in several steps.

First, filter out loci with too much missing data:

	./plink --file input-name --geno 0.5 --recode --out output-filename_a --noweb

Second, filter out individuals with too much missing data:

	./plink --file input-filename_a --mind 0.5 --recode --out output-filename_b --noweb
	
Third, filter out minor allele frequency:

	./plink --file input-filename_b --maf 0.01 --recode --out output-filename_c --noweb
 
Filter out several levels of missing data and of minor allele frequencies to evaluate missingness of final matrix and potential population metrics that vary (esp. with maf filters). 

[These](https://github.com/pesalerno/PUMAgenomics/blob/master/maf-filters.results.txt) are the results that I got with Daryl's dataset. 

**ADDITIONAL FILTER:** We found in our fastQC results shown [here]() *add picture from result* that after base #94 there were a high number of SNPs which were likely due to sequencing error. To filter them out, we first saw the number of times base #90-96 were found in a given SNP list using the following code: 

	cat loci-rows.txt | awk '/_90/ {count++} END {print count}'
	
	cat loci-rows.txt | awk '/_96/ {count++} END {print count}' 


We decided to only eliminate the last base sequenced (#95) from the SNP file based on the [numbers obtained](https://github.com/pesalerno/PUMAgenomics/blob/master/loci-SNPs.txt). 

In order to create a blacklist of loci to eliminate from the SNP matrix, we used the following **grep** commands with the **.map** output from ***populations*** as follows: 

	\d\t(\d*_\d*)\t\d\t\d*$ ##find
	\1 ##replace

Saving the file as "loci_rows-to-filter.txt", we then saved the list of loci that should be blacklisted using this code: 

	cat loci_rows-to-filter.txt | awk '/_95/ {print}' > blacklist_95.txt


We then eliminated those loci using ***plink***, the .ped and .map outputs from populations and the blacklist of SNP position #95 using with the following code: 

	plink --file Puma-filtered-maf_01 --exclude blacklist_95.txt --recode --out filtered_b --noweb
	### file terminations don't need to be added if flag is --file


Re-running **populations** with a whitelist of loci and individuals that passed filters
------

To be able to successfully run *populations* with this new set of loci, we need to make a ***whitelist*** file that only has the locis ID and excludes the SNP position ID. Thus, only the first string before the underscore needs to be kept. The whitelist file format is ordered as a simple text file containing one catalog locus per line: 

		3
		7
		521
		11
		46
		103
		972
		2653
		22
		
		
We decided to use the final filters of loci with 75% individuals sequenced, individuals with no less than 50% missing data, maf 0.01, and filtering out the last sequnced base (#95). This final matrix had 12456 SNPs and a genotyping rate of 0.88. The structure matrix can be found [here](https://github.com/pesalerno/PUMAgenomics/blob/master/Puma_filtered_08_17_17.stru). 


In order to get the nice *populations* stats outputs from STACKS, we need to re-run populations using a whitelist. To get this, open the ***.map*** file from the last ***plink*** output in Text Wrangler, and do find and replace arguments using **grep**:


	search for \d\t(\d*)_\d*\t\d\t\d*$
	replace with \1

Using the **.irem** file from the second iteration of *plink* (in our example named with termination **"_b"**), remove any individuals from the first popmap if they did not pass **plink** filters so that they are excluded from the analysis (i.e. individuals with too much missing data). 



Now we can run populations again using the whitelist of loci and the updated popmap file for loci and individuals to retain based on the plink filters. 

	populations -b 1 -P ./ -M ./popmap.txt  -p 1 -r 0.5 -W Pr-whitelist --write_random_snp --structure --plink --vcf --genepop --fstats --phylip

	##eliminate the --vcf output flag if you want to save computational time! can take hours to write.... 


Basic ***adegenet*** and population stats analyses for the best filtering schemes
-----


We ran ***adegenet*** for the more stringent filtered matrix (loci of more than 75% individuals genotyped) and the three maf filters. [We found](https://github.com/pesalerno/PUMAgenomics/blob/master/Pop_ID.pdf) that there was very little change from maf 0.01 to maf 0.02, and essentially no change from maf 0.02 to 0.05. 


The R code used for these analyses and for PCAdapt can be found [here](https://github.com/pesalerno/PUMAgenomics/blob/master/Pumas-adegenet.R) and continues to be updated. 


Here are the final [population stats]()  for the cleaned matrix  and the [PCA]() and [DAPC]() and [PCAdapt]() results. 
