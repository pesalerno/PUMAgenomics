# Useful, miscellaneous bits of code

Here are some useful, basic things that I've come across, particularly for using the Unix command line to edit large text files.

This is also my first time using markdown or uploading to github...fingers crossed!

##Remove first line from text file

Useful for getting rid of the first comment line that Stacks adds to all its output files. This is necessary for getting certain scripts and programs to run using these files.

>sed -i.bak 1d /path/to/file

This also creates a backup of the original file with the extention '.bak'. You can also use the wildcard (*) to do multiple files at once.

##Remove line based on individual label

This will remove an entire line of a text file that contains a keyword. This is particularly useful when you want to delete individuals from a large genepop or other input file.

>sed -i.bak '/pattern to match/d' ./path/to/file

This will also create a backup as above. Replace where it says 'pattern to match' with a keyword from the line you want to delete. Beware that this will delete all lines containing that word, so it's best for unique identifiers like sample names, for example:

>sed -i.bak '/VC_X1528/d' ./batch_1.structure.tsv

##Sample a subset of SNPs following Stacks denovo assembly

Produces a whitelist file containing a random subset of SNPs from your denovo assembly that you can then give to populations. This is great if you want to test out some analyses without having to input all of your SNPs at once, which tends to be a lot slower! Julian Catchen himself posted this one on the Stacks Google Group.

>grep -v "^#" batch_1.sumstats.tsv | 
cut -f 2 | 
sort | 
uniq | 
shuf | 
head -n 1000 | 
sort -n > whitelist.tsv 

Julian:
>This command does the following at each step: 
 > 
 > 1) Grep pulls out all the lines in the sumstats file, minus the commented header lines. The sumstats file contains all the polymorphic loci in the analysis. 
 > 2) cut out the second column, which contains locus IDs 
 > 3) sort those IDs 
 > 4) reduce them to a unique list of IDs (remove duplicate entries) 
 > 5) randomly shuffle those lines 
 > 6) take the first 1000 of the randomly shuffled lines 
 > 7) sort them again and capture them into a file. 
 > 
 > So, this will pull out all the polymorphic catalog IDs, shuffle them and capture the first 1000 random IDs into a file. You then run populations again and give this file to populations as a whitelist (-W) flag. Populations then will only process these 1000 random loci. 
 > 
 > If you repeat this command a few times and compare the outputs, say: 
 > 
 >>>head -n 25 whitelist_1000-1.tsv whitelist_1000-2.tsv 
 > 
 > you should see different sets of IDs in the files. 
 > 
 > If you want more than 1000 loci, just put in the number you want (1000-5000 loci seems to work well with STRUCTURE, but it can't handle huge numbers of loci). 