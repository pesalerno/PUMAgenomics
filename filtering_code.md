Filtering SNPs that come after base 94 (based on the FastQC results):
-------


First, we saved  loci IDs as rows instead of columns (in excel or any other creative way you can find), then:

	cat loci-rows.txt | awk '/_90/ {count++} END {print count}'
	
	cat loci-rows.txt | awk '/_96/ {count++} END {print count}'

To find number of occurences of SNPs in those positions within the locus, then do: 

	cat loci-rows.txt | awk '/_94/ {print}' > blacklist_95.txt
	cat loci-rows.txt | awk '/_95/ {print}' > blacklist_96.txt

To exclude loci based on position of SNP that is likely sequencing error. Here's what the [number of SNPs](https://github.com/pesalerno/PUMAgenomics/blob/master/loci-SNPs.txt)were for the last six bases of the SNPs. 

	





