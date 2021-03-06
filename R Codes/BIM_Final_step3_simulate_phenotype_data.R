#-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
#-----||-----||-----||Step 3 - RCode simulate phenotype models||-----||-----||-----||-----#
#-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#


#-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
#-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
#-----||-----|| Goal: Simulate two continuous phenotypes based on our||-----||-----||-----#
#-----||-----||genetic data. Then, re-format our data with phenotypes||-----||-----||-----#
#-----||-----||That is, create data frames where the first 2 columns ||-----||-----||-----#
#-----||-----||are the phenotypes, and the remaining columns are the ||-----||-----||-----#
#-----||-----||SNP sites where entries correspond to number of Minor ||-----||-----||-----#
#-----||-----|| alleles at the SNP site.                             ||-----||-----||-----#
#-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
#-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#

source("/global/home/hpc4300/BIM_Final_RCodes/BIM_Rcode_Simulation_help.R")


#  -----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----   #
#-----||-----||-----||-----||-----||Array Job Code:||-----||-----||-----||-----||-----||-----#
#  -----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----   #
#I set an aray job with 100 "arrays". I will split up the files to analyse into 100 chunks:
#There are 3000 files in total to potentially analyse, so I split this into 100 chunks with
#30 files belonging to each chunk.

slurm_arrayid <- Sys.getenv('SLURM_ARRAY_TASK_ID')
task_id <- as.numeric(slurm_arrayid)
#Obtain Slurm Task ID.  


#Now, determine indices of data files to analyse:
total_files=seq(from=1, to= 3001, by=30)

starting = total_files[task_id]
#Compute starting index

ending = total_files[task_id +1] - 1
#Compute ending index

for (j in (starting:ending)){
  setwd("/global/home/hpc4300/BIM_Final_Clean_Data")
  
  ## STEP 1: Read in the haplotype data. Must specify that it is type "character". 
  filename = paste("haplodata",j, ".txt", sep="")
  
  if (!file.exists(filename)){
    next
  #This is just an added sanity check. To proceed, we need to ensure the file actually exists...
    }
  
  
  haplodat=read.table(filename, colClasses=c("character"))
  
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  #-----||-----||-----||-----||-----||Obsolete Code||-----||-----||-----||-----||-----||-----#
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  #The following code was used to obtain the number of SNP sites. But, further research (by me)
  # has shown that some SNPs are perfectly correlated. We will only keep SNP sites that are not
  # perfectly correlated.
  #
  #
  #The first line of the haplotype data will be used to calculate the number of segregation sites,
  #otherwise known as the number of SNP sites.
  #UPDATE: We actually need the following code. The variable segsites will be given a new value
  # soon... 12/15/18
  FirstLine = readLines(filename)[1]
  FirstLine=unlist(strsplit(FirstLine,split=""))
  segsites=length(FirstLine)
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  
  
  ## Note that the loci are not separated by spaces. So we must split them in order to be able to manipulate the data. 
  ## Also convert to type numeric so that we can add allele counts
  newhaplodat=matrix(as.numeric(unlist(strsplit(haplodat[,1],split=""))),ncol=segsites,byrow=T)
  
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  #What if columns are the exact same? (I.E 100% correlated between SNPs?) Let's remove them.
  
  newhaplodat = unique.matrix(t(newhaplodat)) 
  #Returns a matrix with only unique ROWS (so I need the transpose)
  
  newhaplodat = t(newhaplodat)
  #*** If this section was too confusing, I've added a more in-depth explanation in my ReadME file.
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  
  segsites = ncol(newhaplodat)
  
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  ##The following code can be used to check if our data manipulation above succeeded:
  #haplodat[24,]
  #newhaplodat[24,]
  #haplodat[186,]
  #newhaplodat[186,]
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  
  
  
  
  #STEP 2: Make sure our data is in terms of the Minor Allele.
  
  ## Get allele frequencies
  f1=colSums(newhaplodat)/nrow(newhaplodat)
  
  ## We want allele frequencies to be in terms of minor allele frequencues (MAF)
  # So.... if MAF>0.5, we ned to reverse the coding:
  tochange=which(f1>0.5)
  
  
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  #***I ADDED THE FOLLOWING IF STATEMENT IN CASE tochange RETURNS logical(0)
  #I.E. We do not need to change our data format if it is already in terms of the MAF...
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  if (length(tochange) !=0){
    for (i in 1:length(tochange)){
      index=tochange[i]
      newhaplodat[,index]=1-newhaplodat[,index]
    }
  }
  
  
  
  ## STEP3: Create genotype dataset. This is done by pairing consecutive rows
  # Ex: Individual 1's genotype will be comprised of haplotypes from row 1 and 2 from our data.
  #Individual 2's genotype will be calculated from haplotypes from row 3 and 4. etc...
  
  
  genodat=matrix(nrow=nrow(haplodat)/2,ncol=ncol(newhaplodat))
  #initializing step...
  
  for (i in 1:nrow(genodat)){
    genodat[i,]=newhaplodat[2*i-1,]+newhaplodat[2*i,]
  }
  
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  #What if columns are the exact same? (I.E 100% correlated between SNPs?) Let's remove them.
  
  genodat = unique.matrix(t(genodat)) 
  #Returns a matrix with only unique ROWS (so I need the transpose)
  
  genodat = t(genodat)
  #*** If this section was too confusing, I've added a more in-depth explanation in my ReadME file.
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  
  segsites = ncol(genodat)
  
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  
  
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  ##Again, we can use the following code to check if our data manipulation above succeeded:
  #i=99
  #newhaplodat[(2*i-1):(2*i),]
  #genodat[i,]
  #-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#
  
  
  
  ## STEP 4: Simulate some continuous phenotype data. Both models chosen so that power is around 60%

  
  
  #-----||-----||-----||-----||Phenotype 1 causal site||-----||-----||-----||-----||-----#
  common.causal=get_common_causal(genodata=genodat)
  #Obtain a random common causal site (we can cange the bounds of the MAF. It is 
  #by default set at (0.25, 0.35)).

  if(is.null(common.causal)){
    file.remove(filename)
    next
    #If our dataset does not have any SNP sites that can be the common causal variant,
    #then we just skip to next iteration.
  }
  
  
  
  #-----||-----||-----||-----||Phenotype 2 causal sites||-----||-----||-----||-----||-----#
  rare.causal=get_rare_causals(genodata=genodat, UpperBound=0.05, LowerBound=0)
  #Obtain 10 random sites to act as the rare causal sites.
  
  if(is.null(rare.causal)){
    file.remove(filename)
    next
  }
  

  hascausal=rowSums(genodat[,rare.causal])
  #This computes marginal counts of rare causal variants each individual has.
  
  
  
  ##Now, we simulate the data.
  y1 = sim_pheno1(beta=0.55, common.causal = common.causal)
  y2 = sim_pheno2(beta =1.1, rare.causal = hascausal )
  
  genodat=data.frame(y1,y2,genodat)
  colnames(genodat)=c("Pheno1","Pheno2",paste("V",1:segsites,sep=""))

  
  #-----||-----||Save our simulated phenotypes in a file||-----||-----||-----#
  table_name = paste("NoRecomb_PhenoAndGeno", j, ".txt", sep="")
  
  setwd("/global/home/hpc4300/BIM_Final_PhenoAndGeno_Data")
  write.table(genodat, table_name, quote=F,row=F,col=F)
  
  
}


