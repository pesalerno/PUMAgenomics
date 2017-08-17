Filtering SNPs that come after base 94 (based on the FastQC results):
-------


First, save your loci IDs as rows instead of columns (in excel or any other creative way you can find), then do:

	cat loci-rows.txt | awk '/_95/ {count++} END {print count}'
	
	cat loci-rows.txt | awk '/_96/ {count++} END {print count}'

To find number of occurences of SNPs in those positions within the locus, then do: 

	cat loci-rows.txt | awk '/_96/ {print}' > blacklist_95.txt
	cat loci-rows.txt | awk '/_96/ {print}' > blacklist_96.txt

To exclude loci based on position of SNP that is likely sequencing error. Here's what the [result](https://github.com/pesalerno/PUMAgenomics/blob/master/loci-SNPs.txt) looks like. 

	





