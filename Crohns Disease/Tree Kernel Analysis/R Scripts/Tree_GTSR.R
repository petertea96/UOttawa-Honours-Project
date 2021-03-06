####Peter's attempt at forming GTSR model. Most of this work was completed by Zhe with just
# a couple of minor tweaks completed by yours truly.


.libPaths("/global/home/hpc4300/RPackages")
similarity.regression.tree = function(P1,n, kernel.list ){
  
  phenotype1_model = lm(P1~1)
  
  ## compute vector of (P1i -mu.p1_0)
  residuals_P1 = resid(phenotype1_model)
  
  ## compute n by n trait similarity matrix of phenotype 1
  Z_ij = residuals_P1%*%t(residuals_P1)
  
  
  
  #####||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#####
  #July 25th, 2018
  #N is the number of upper diagonal elements?
  N = sum(upper.tri(Z_ij))
  
  
  ##I extract the values of the upper diagonal of matrices Z1
  z1 <-c(rep (0,N))
  count = 1
  for (i in 1:(n -1)) {
    for (j in (i +1): n) {
      z1[ count ]= Z_ij[i,j]
      count = count + 1
    }
  }
  
  #chr is a vector of list names of the kernels???
  ##chr=c("S_IBS", "S_AM", "S_AS", "S_LIN", "S_REC", "S_QUAD", "S_012", "S_123",
  ##     "S_124", "S_h1", "skat.kernel","tree1", "tree2", "tree3", "tree4", "tree5")
  
  chr=c("tree1", "tree2", "tree3", "tree4", "tree5")
  
  #s_vectors: The columns of s_vector contain similarities of distinct pairs of individuals by
  #each kernel. I assume that it is of dimension (16x4950)
  
  s_vectors = c()
  for (i in 1:length(kernel.list)){
    kernel = kernel.list[[i]]
    #Extract the upper diagonal:
    upper_diagonal <-c(rep (0,N))
    count = 1
    for (ii in 1:(n -1)) {
      for (j in (ii +1): n) {
        upper_diagonal[count]= kernel[ii,j]
        count = count + 1
      }
    }
    s_vectors=cbind(s_vectors,upper_diagonal)
  }
  colnames(s_vectors) = chr
  
  #####||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----||-----#####
  
  
  
  ## check the equality of last two values
  # z1[N -1] == Z1[n -2,n]
  #z1[N] == Z1[n -1,n]
  
  ## 1. Phenotype 1
  ## compute wald test statistic of phenotype 1 stored in vector: wald.pheno1
  wald.pheno1 = matrix (rep(0, length(chr)), ncol = length(chr))
  for (i in 1: length(chr)) {
    gene_trait_lm  = lm(z1~ s_vectors[,i])
    wald.pheno1[i] =(summary(gene_trait_lm)$coefficients[2 ,3])^2
  }
  ## compute permuted wald test statistic of phenotype 1
  ## stored in matrix wald.pheno1.permu
  ## recall the columns of s_ vectors contains similarities of distinct pairs
  ## of individuals computed based on a particular kernel

  colnames(wald.pheno1) = chr
  ## compute permuted p- values of phenotype 1 denoted by permu .p1.p
 
  return(as.vector(wald.pheno1))
  
  
  
  
  
}
