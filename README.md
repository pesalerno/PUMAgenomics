PUMAgenomics
======
All the material in this repository is Intellectual Property of PE Salerno, D Trumbo and WC Funk @ Colorado State University. To use content, please cite accordingly. 


-----

I made a short protocol on some practices for easy git collaborating that can be found [here](https://github.com/pesalerno/PUMAgenomics/blob/master/git-collaborating-protocol.md). 


 

Demultiplexing in stacks
-----

The code used for demultiplexing and cleaning reads in ***process_radtags*** was:

	process_radtags -f /path/to/file/sequence.fastq -b /path/to/file/barcodes-names.txt -o /path/output-folder -c -q -r -D -e nlaIII -i fastq



Estimating genotyping error and optimizing stacks parameters 
-----

This is following the [Mastretta-yanes et al 2015](http://onlinelibrary.wiley.com/doi/10.1111/1755-0998.12291/abstract) paper. First, we ran several iterations of the parameters in denovo_map in order to explore parameter space with the R code of Mastretta-Yanes. You only need to run these analyses with the intra- and inter- library replicates. 



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

After finding the lowest genotyping error rate for our dataset and the appropriate *denovo_map.pl* parameters, we used the following code for our final genotyping:


        denovo_map.pl -T 16 -m 5 -M 2 -n 2 -S -b 2 -X "ustacks:--max_locus_stacks [3]" -o /path/to/denovomap_out/ \
        -s /path/to/rad_tags/filename.fq \ 

_________
_________
We haven't really run the analyses with rxstacks... do we just elminate this for this pub? I think it's generally ok, but if it's done, we can add it somehow

After genotyping, re-run dataset using ***rxstacks***

	>>rxstacks
	#!/bin/bash
	#SBATCH cluster specific information 

        mkdir /path/to/rxstacks-out
        rxstacks -b 2 -P /path/to/denovomap_out -o /path/to/rxstacks-out --conf_filter --prune_haplo --model_type bounded --bound_high 0.1 --lnl_lim -10.0 -t 8

Need to re-run cstacks and sstacks portion of stacks pipeline. 
_________
_________


Filtering SNP matrix.
------

After genotyping, we first exported the SNP matrix with minimal filter in *populations* you are done, use minimum filter settings in **Stacks** in order to get the most complete matrix to LATER filter in plink. 

	>>populations 
	#!/bin/bash
	#SBATCH cluster specific information 

	populations -b 2 -P /project/wildgen/rgagne/combine/populations/pop-comb-c/ -M /project/wildgen/rgagne/combine/populations/pop-map-combine -fstats -k -p 1 -r 0.2  -t 8 --structure --genepop --vcf --plink --write_random_snp



Using [PLINK](http://pngu.mgh.harvard.edu/~purcell/plink/summary.shtml), we filtered our dataset in several steps.

First, we filtered out loci with too much missing data:

	./plink --file input-name --geno 0.5 --recode --out output-filename_a --noweb

Second, we filtered out individuals with too much missing data:

	./plink --file input-filename_a --mind 0.5 --recode --out output-filename_b --noweb
	
Third, we filtered out based on minor allele frequency cutoffs:

	./plink --file input-filename_b --maf 0.01 --recode --out output-filename_c --noweb
 
We did three maf cutoffs (0.01, 0.02, 0.05) to evaluate missingness of final matrices and whether basic population analyses vary with them. Based on [these](https://github.com/pesalerno/PUMAgenomics/blob/master/maf-filters.results.txt) results, we decided to be more stringent on initial loci filtered out (keep loci present in at least 75% of individuals) and less stringent on maf (filter out loci with maf<0.01). 

**ADDITIONAL FILTER:** We found that after base #94 there were a high number of SNPs ([see here](https://github.com/pesalerno/PUMAgenomics/blob/master/reads-SNPposition.png)which were likely due to sequencing error. To filter them out, we first saw the number of times base #90-96 were found in a given SNP list using the following code: 

	cat loci-rows.txt | awk '/_90/ {count++} END {print count}'
	
	cat loci-rows.txt | awk '/_96/ {count++} END {print count}' 


We decided to only eliminate the last base sequenced (#95) from the SNP file based on the [numbers obtained](https://github.com/pesalerno/PUMAgenomics/blob/master/loci-SNPs.txt). In order to create a blacklist of loci to eliminate from the SNP matrix, we used the following **grep** commands with the **.map** output from ***populations*** as follows: 

	\d\t(\d*_\d*)\t\d\t\d*$ ##find
	\1 ##replace

Saving the file as "loci_rows-to-filter.txt", we then saved the list of loci that should be blacklisted using this code: 

	cat loci_rows-to-filter.txt | awk '/_95/ {print}' > blacklist_95.txt


We then eliminated those loci using ***plink***, the .ped and .map outputs from populations and the blacklist of SNP position #95 using with the following code: 

	plink --file Puma-filtered-maf_01 --exclude blacklist_95.txt --recode --out filtered_b --noweb
	### file terminations don't need to be added if flag is --file


Obtaining population stats using the program **populations** with a whitelist of loci and individuals that passed filters
------
	
For downstream analyses, we used the final filters of loci with 75% individuals sequenced, individuals with no less than 50% missing data, maf 0.01, and filtering out the last sequnced base (#95). This final matrix had 12456 SNPs and a genotyping rate of 0.88. The structure matrix can be found [here](https://github.com/pesalerno/PUMAgenomics/blob/master/Puma_filtered_08_17_17.stru). 


In order to get the *populations* stats outputs from STACKS, we re-ran populations using a whitelist, which requires file that only has the locis ID and excludes the SNP position ID. Thus, only the first string before the underscore needs to be kept. The whitelist file format is ordered as a simple text file containing one catalog locus per line: 

		3
		7
		521
		11
		46

We used the ***.map*** output from the last ***plink*** filter in Text Wrangler, and generated the populations whitelist using find and replace arguments using **grep**:


	search for \d\t(\d*)_\d*\t\d\t\d*$
	replace with \1

Based the **.irem** file from the second iteration of *plink* we removed from the popmap (to use in populations input) the only  individual that did not pass **plink** filter (i.e. individuals with >50% missing data). Now we can run populations again using the whitelist of loci and the updated popmap file for loci and individuals to retain based on the plink filters. 

	populations -b 1 -P ./ -M ./popmap.txt  -p 1 -r 0.5 -W Pr-whitelist --write_random_snp --structure --plink --vcf --genepop --fstats --phylip

	


Filtering out outlier loci
------

We ran PCAdapt using [this code](https://github.com/pesalerno/PUMAgenomics/blob/master/Pumas-adegenet.R) and found only 12 outliers (using K=2). PCAdapt outputs the "order" of the loci rather than the IDs of the loci themselves, so to exclude the outliers we generated a blacklist like this:


	awk '{print $2495,$2800,$5456,$5556,$7894,$8230,$8875,$10204,$11417,$11493,$12255,$12277}' puma-FINAL.stru > blacklist-PCAdapt-b

Which generates a line of the loci, the doing find *"space"* and replace with *"new line"* (\n) we obtained our final blacklist file for excluding SNPs based on PCAdapt. 


Basic ***adegenet*** and population stats analyses for the best filtering schemes
-----


We ran ***adegenet*** for the more stringent filtered matrix (loci of more than 75% individuals genotyped) and the three maf filters. [We found](https://github.com/pesalerno/PUMAgenomics/blob/master/Pop_stats.pdf) that there was very little change from maf 0.01 to maf 0.02, and essentially no change from maf 0.02 to 0.05. 


The R code used for these analyses and for PCAdapt can be found [here](https://github.com/pesalerno/PUMAgenomics/blob/master/Pumas-adegenet.R) and continues to be updated. 


Here are the final results for the cleaned matrix: [PCA](https://github.com/pesalerno/PUMAgenomics/blob/master/Puma_CO_PCA.pdf), [DAPC](https://github.com/pesalerno/PUMAgenomics/blob/master/Puma_CO_DAPC.pdf), [compoplot](https://github.com/pesalerno/PUMAgenomics/blob/master/Puma_CO_compoplot.pdf) and [PCAdapt](https://github.com/pesalerno/PUMAgenomics/blob/master/PCAdapt-outliers.txt). 
