library("ape")
library("pegas")
library("seqinr")
library("ggplot2")
library("adegenet")
library("hierfstat")



#myFile <- import2genind("Puma_75_maf_01.stru") ##12786 SNPs and 134 inds
#myFile <- import2genind("Puma_75_maf_02.stru") ##11915 SNPs and 134 inds
#myFile <- import2genind("Puma_75_maf_05.stru") ###10315 SNPs and 134 inds

myFile <- import2genind("Puma_filtered_08_17_17_POP1.stru") #12456 SNPs and 134 inds


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
			ncol=1,xlab="individuals") ##using original population IDs

##lab<-pop(myFile)
##compoplot(dapc2,subset=1:50, posi="bottomright",lab="",
			ncol=2, lab="lab")

##To find the potential migrant IDs:
assignplot(dapc2, subset=1:10)			
assignplot(dapc2, subset=51:100)
assignplot(dapc2, subset=101:134)

####################################
###  PCAdapt ANALYSIS - Re-Done ####
####################################
###loading package and file
library(pcadapt)
file<-"puma-FINAL.ped"
myFile<-read.pcadapt(file, type="ped")
myFile
#NOTE:by default data is assumed to be diploid

##################################
### 1. DETERMINE THE DESIRED K ###
##################################
x <- pcadapt(myFile, K=20) ###default maf = 0.05
plot(x,option="screeplot")
##The idea is to choose the number of PCs after which population structure
##is not evident. The "ideal" cluster scenario seems to be rarly seen 
##(definitely in my datasets), so sometimes it's a little tricky. In this case, 
##I believe there is a choice between K=2 (MOST of the structure) and K=4 (ALL 
##of the structure). 

##We could also mess around with maf thresholds and see if a different number of K is inferred...? 
x2 <- pcadapt(myFile, K=20, min.maf = 0.01)
plot(x2,option="screeplot") ##RESULT: NOPE!! they look exactly hte same... 

####################################
### 2. GENOME SCANS WITH PCAdapt ###
####################################
library(qvalue)
##We will infer outliers using two thresholds of K and two thresholds of maf: 
##1. K=2, maf=0.05
x<-pcadapt(myFile,K=2)
plot(x,option="manhattan", threshold=0.1)
plot(x,option="qqplot", threshold=0.1)
hist(x$pvalues,xlab="p-values",main=NULL,breaks=50)
plot(x,option="stat.distribution")
qval<-qvalue(x$pvalues)$qvalues
alpha<-0.1
outliers<-which(qval<alpha)
get.pc(x, outliers)

##################
##2. K=2, maf=0.01
x2<-pcadapt(myFile,K=2, min.maf = 0.01)
plot(x2,option="manhattan", threshold=0.1)
plot(x2,option="qqplot", threshold=0.1)
hist(x2$pvalues,xlab="p-values",main=NULL,breaks=50)
plot(x2,option="stat.distribution")
qval2<-qvalue(x2$pvalues)$qvalues
alpha2<-0.1
outliers2<-which(qval2<alpha2)
get.pc(x2, outliers2)

##################
##3. K=4, maf=0.05
x3<-pcadapt(myFile,K=4, min.maf = 0.05)
plot(x3,option="manhattan", threshold=0.1)
plot(x3,option="qqplot", threshold=0.1)
hist(x3$pvalues,xlab="p-values",main=NULL,breaks=50)
plot(x3,option="stat.distribution")
qval3<-qvalue(x3$pvalues)$qvalues
alpha3<-0.1
outliers3<-which(qval3<alpha3)
get.pc(x3, outliers3)

##################
##4. K=4, maf=0.01
x4<-pcadapt(myFile,K=4, min.maf = 0.01)
plot(x4,option="manhattan", threshold=0.1)
plot(x4,option="qqplot", threshold=0.1)
hist(x4$pvalues,xlab="p-values",main=NULL,breaks=50)
plot(x4,option="stat.distribution")
qval4<-qvalue(x4$pvalues)$qvalues
alpha4<-0.1
outliers4<-which(qval4<alpha4)
get.pc(x4, outliers4)

