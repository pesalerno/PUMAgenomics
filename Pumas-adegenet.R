library("ape")
library("pegas")
library("seqinr")
library("ggplot2")
library("adegenet")
library("hierfstat")



#myFile <- import2genind("Puma_75_maf_01.stru") ##12786 SNPs and 134 inds
#myFile <- import2genind("Puma_75_maf_02.stru") ##11915 SNPs and 134 inds
#myFile <- import2genind("Puma_75_maf_05.stru") ###10315 SNPs and 134 inds

myFile <- import2genind("Puma_filtered_08_17_17.stru") #12456 SNPs and 134 inds


##QUESTIONS FOR STRUCTURE FILES:
### Which column contains the population factor ('0' if absent)? 
###answer:2
###Which other optional columns should be read (press 'return' when done)? 
###Which row contains the marker names ('0' if absent)? 
###Answer:1

myFile ##look at your transformed genind file


########################
help(scaleGen)
X <- scaleGen(myFile, NA.method="zero")
X[1:5,1:5]



pca1<-dudi.pca(X,cent=FALSE,scale=FALSE,scannf=FALSE,nf=3)
myCol <-c("darkgreen","darkblue")
s.class(pca1$li,pop(myFile), col=myCol)
add.scatter.eig(pca1$eig[1:20], 3,1,2)

###############
###############

plot(pca1$li, col=myCol, cex=3)
###to plot with funky colors
s.class(pca1$li,pop(myFile),xax=1,yax=2,col=myCol,axesell=FALSE,
		cstar=0,cpoint=3,grid=FALSE)


############################################
#####   to find names of outliers    #######
############################################
s.label(pca1$li)




################################################
###  NEIGHBOR-JOINING TREE COMPARED TO PCA   ###
################################################
library(ape)
tre<-nj(dist(as.matrix(X)))
plot(tre,typ="fan",cex=0.7)


myCol<-colorplot(pca1$li,pca1$li,transp=TRUE,cex=4)
abline(h=0,v=0,col="grey")


plot(tre,typ="fan",show.tip=FALSE)
tiplabels(pch=20,col=myCol,cex=2)




####################################
#####   DAPC by original pops   ####
####################################


dapc2<-dapc(X,pop(myFile))
dapc2
scatter(dapc2)
summary(dapc2)
contrib<-loadingplot(dapc2$var.contr,axis=1,thres=.07,lab.jitter=1)



####################
###  COMPOPLOT   ###
####################

compoplot(dapc2,posi="bottomright",lab="",
			ncol=1,xlab="individuals")


##lab<-pop(myFile)
##compoplot(dapc2,subset=1:50, posi="bottomright",lab="",
			ncol=2, lab="lab")


##To find the potential migrant IDs:
assignplot(dapc2, subset=1:10)			
assignplot(dapc2, subset=51:100)
assignplot(dapc2, subset=101:134)


###################################################
###     DIVERSITY AND POPULATION MEASURES       ###
###################################################

library(hierfstat)
####load dataset with struture-informed populations


basicstat<-basic.stats(myFile, diploid=TRUE)
basicstat
Hobs<-basicstat$Ho
Hobs
write(Hobs, file="Xr-Hobs-03-22.txt", ncol=7)

Hexp<-basicstat$Hs
Hexp
write(Hexp, file="Xr-Hexp-03-22.txt", ncol=7)

Fis<-basicstat$Fis
Fis
write(Fis, file="Xr-Fis-03-22.txt", ncol=7)

bartlett.test(list(basicstat$Hs, basicstat $Ho)) ##this gives you a statistical
##measure of whether observed and expected heterozygosity are different


library(diveRsity)
divBasic(infile=".stru", outfile="", gp=2, bootstraps=NULL, HWEexact=FALSE)


##########################
###  PCAdapt PACKAGE  ####
##########################
library(pcadapt)

file<-"puma-FINAL.ped"
myFile<-read.pcadapt(file, type="ped")


#by default data is assumed to be diploid
x <- pcadapt(myFile, K=20) 
##to choose number of PCs based on proportion of variance
plot(x,option="screeplot")

##to choose number of PCs based on population structure
####the choice of K can b elimited to the values of K that correspond to a relevant level of population structure

##THEN PICK NUMBER OF K DESIRED
x<-pcadapt(myFile,K=2)
summary(x)

plot(x,option="manhattan")
plot(x,option="qqplot", threshold=0.1)
hist(x$pvalues,xlab="p-values",main=NULL,breaks=50)
plot(x,option="stat.distribution")

###ARBITRATY CUTOFF OF ALPHA VALUES TO CONSIDER OUTLIERS

library(qvalue)
qval<-qvalue(x$pvalues)$qvalues
alpha<-0.1
outliers<-which(qval<alpha)
print(outliers)
outliers

##which PCs are most correlated to the outliers?
snp_pc<-get.pc(x,outliers)
head(snp_pc)
snp_pc


