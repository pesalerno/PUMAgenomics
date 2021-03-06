PUMAgenomics
======
All the material in this repository is Intellectual Property of PE Salerno, D Trumbo and WC Funk @ Colorado State University. To use content, please cite accordingly. 


----

Demultiplexing in stacks
-----

The code used We used  ***process_radtags*** to demultiplex pooled individuals and to filter reads based on Phred quality scores with the following code:

	process_radtags -f /path/to/file/sequence.fastq -b /path/to/file/barcodes-names.txt -o /path/output-folder -c -q -r -D -e nlaIII -i fastq



Estimating genotyping error and optimizing stacks parameters 
-----

Following the library replicates protocol design by [Mastretta-yanes et al 2015](http://onlinelibrary.wiley.com/doi/10.1111/1755-0998.12291/abstract), we ran several iterations of parameter values within suggested ranges in denovo_map in order to explore parameter space. These analyses were only ran with the intra- and inter- library replicates. 



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

Calculate Replicate Error Rates
------

We used [R code from Mastretta-Yanes et al.2015](https://github.com/AliciaMstt/RAD-error-rates) to calculate loci, allele, and SNP error rates.

First, we labeled Stacks output data for individuals and replicates in same directory, e.g., as Sample1 (original), Sample1_r (replicate), etc.
	
Then, we exported data from Stacks into SNP (.snp) and Coverage (.cov) files. In order to create separate MySQL databases for each parameter settings run, we imported Stacks SNP (.snp) and Coverage (.cov) files into MySQL, and exported as tsv files, for calculating loci and allele error rates in R.

	load_radtags.pl -D m3M2n4max3_radtags -p /path/to/denovo/output/folder/m3M2n4max3 -b 1 -B -e "m3M2n4max3" -c -t population
	
	index_radtags.pl -D m3M2n4max3_radtags -s /path/to/stacks/sql -c -t
	
	export_sql.pl -D m3M2n4max3_radtags -b 1 -f /path/to/denovo/output/folder/m3M2n4max3.SNP -o tsv -F pare_l=8 -a haplo -L 2

	export_sql.pl -D m3M2n4max3_radtags -b 1 -f /path/to/denovo/output/folder/m3M2n4max3.COV -o tsv -F pare_l=8 -a haplo -L 2 -d
	

We then used Plink to create plink.raw files, for calculating SNP error rates in R.

	plink --file m3M2n4max3.plink --recode A --out m3M2n4max3

Finally, using the plink output we ran the [Mastretta-Yanes et al. (2015) R packages](https://github.com/AliciaMstt/RAD-error-rates).

(1) LociAllele_error.R using a tsv file (formated as the output of export_sql from Stacks, but keeping only the columns CatalogID Consensus SNPs Sample1 Sample1_r Sample2 ...) converted to a genlight object, to calculate loci and allele error rates.

(2) SNPs_error.R using a plink.raw file converted to a genlight object, to calculate SNP error rates.

Genotyping
-------

After finding the lowest genotyping error rate for our dataset and the appropriate *denovo_map.pl* parameters, we used the following code for our final genotyping:


        denovo_map.pl -T 16 -m 5 -M 2 -n 2 -S -b 2 -X "ustacks:--max_locus_stacks [3]" -o /path/to/denovomap_out/ \
        -s /path/to/rad_tags/filename.fq \ 

_________
_________


Filtering the SNP matrix.
------

After genotyping, we first exported the SNP matrix with minimal filter in *populations* in **Stacks** in order to get the most complete matrix to LATER filter in plink. 

	>>populations 
	#!/bin/bash
	#SBATCH cluster specific information 

	populations -b 2 -P /path/to/populations/pop-comb-c/ -M /path/to/popmap/pop-map.txt -fstats -k -p 1 -r 0.2  -t 8 --structure --genepop --vcf --plink --write_random_snp



Using [PLINK](http://pngu.mgh.harvard.edu/~purcell/plink/summary.shtml), we filtered our dataset in several steps.

First, we filtered out loci with too much missing data (more than 50%) individuals overall:

	./plink --file input-name --geno 0.5 --recode --out output-filename_a --noweb

Second, we filtered out individuals with too much missing data (more than 50%):

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
	
For downstream analyses, we used the final filters of loci with 75% individuals genotyped, individuals with no less than 50% missing data, maf 0.01, and filtering out the last sequnced base (#95). This final matrix had 12456 SNPs and a genotyping rate of 0.88. 


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


The R code used for these analyses and for PCAdapt can be found [here](https://github.com/pesalerno/PUMAgenomics/blob/master/Pumas-adegenet.R). 
