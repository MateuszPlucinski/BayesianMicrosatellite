source("define_alleles.r")
source("calculate_frequencies.r")
source("recode_alleles.r")
source("switch_hidden.r")
source("findposteriorfrequencies.r")

maxMOI = max(as.numeric(sapply(1:length(colnames(genotypedata_RR)), function (x) strsplit(colnames(genotypedata_RR)[x],"_")[[1]][2])),na.rm=TRUE)

ids = unique(unlist(strsplit(genotypedata_RR$Sample.ID[grepl("Day 0",genotypedata_RR$Sample.ID)]," Day 0")))

locinames = unique(sapply(colnames(genotypedata_RR)[-1],function(x) strsplit(x,"_")[[1]][1]))
nloci = length(locinames)

nids = length(ids)

maxalleles=30

k = rep(maxalleles, nloci)
alleles_definitions_RR  = define_alleles(rbind(genotypedata_RR,additional_neutral),locirepeats,k)

##### calculate MOI
MOI0 = rep(0,nids)
MOIf = rep(0,nids)
for (i in 1:nids) {
	for (j in 1:nloci) {
		locicolumns = grepl(paste(locinames[j],"_",sep=""),colnames(genotypedata_RR))
		nalleles0 = sum(!is.na(genotypedata_RR[grepl(paste(ids[i],"Day 0"),genotypedata_RR$Sample.ID),locicolumns]))
		nallelesf = sum(!is.na(genotypedata_RR[grepl(paste(ids[i],"Day Failure"),genotypedata_RR$Sample.ID),locicolumns]))

		MOI0[i] = max(MOI0[i],nalleles0)
		MOIf[i] = max(MOIf[i],nallelesf)
	}
}
#maxMOI = max(MOI0,MOIf)


##### define statevector

alleles0 = matrix(0,nids,maxMOI*nloci)
recoded0 = matrix(0,nids,maxMOI*nloci)
hidden0 = matrix(NA,nids,maxMOI*nloci)
recr0 = matrix(NA,nids,nloci)
recr_repeats0 = matrix(NA,nids,nloci) # number of times recrudescing allele is repeated on day 0
recr_repeatsf = matrix(NA,nids,nloci) # number of times recrudescing allele is repeated on day 0
allelesf = matrix(0,nids,maxMOI*nloci)
recodedf = matrix(0,nids,maxMOI*nloci)
hiddenf = matrix(NA,nids,maxMOI*nloci)
recrf = matrix(NA,nids,nloci)
if (length(additional_neutral) > 0) { if (dim(additional_neutral)[1] > 0) {
	recoded_additional_neutral = matrix(0,dim(additional_neutral)[1],maxMOI*nloci)
}}
mindistance = matrix(0,nids,nloci)
alldistance = array(NA,c(nids,nloci,maxMOI*maxMOI))
allrecrf = array(NA,c(nids,nloci,maxMOI*maxMOI))
classification = rep(0,nids)
##### create state 0

for (j in 1:nloci) {
	locus = locinames[j]
	locicolumns = grepl(paste(locus,"_",sep=""),colnames(genotypedata_RR))
	oldalleles = as.vector(genotypedata_RR[,locicolumns])
	if (length(dim(oldalleles)[2]) == 0) {
		oldalleles = matrix(oldalleles,length(oldalleles),1)
	}
	newalleles = oldalleles
	ncolumns = dim(oldalleles)[2]
	for (i in 1:ncolumns) {
		newalleles[,i] = (sapply(1:dim(oldalleles)[1],function (x) recodeallele(alleles_definitions_RR[[j]],oldalleles[x,i])))
	}
	newalleles = matrix(as.numeric(unlist(c(newalleles))),dim(newalleles)[1],dim(newalleles)[2])
	newalleles[is.na(newalleles)] = 0
	oldalleles = matrix(as.numeric(unlist(c(oldalleles))),dim(oldalleles)[1],dim(oldalleles)[2])
	oldalleles[is.na(oldalleles)] = 0

	oldalleles[newalleles == 0] = 0
	alleles0[,(maxMOI*(j-1)+1) : (maxMOI*(j-1) + dim(oldalleles)[2])] = oldalleles[grepl("Day 0",genotypedata_RR$Sample.ID),]
	allelesf[,(maxMOI*(j-1)+1) : (maxMOI*(j-1) + dim(oldalleles)[2])] = oldalleles[grepl("Day Failure",genotypedata_RR$Sample.ID),]
	recoded0[,(maxMOI*(j-1)+1) : (maxMOI*(j-1) + dim(newalleles)[2])] = newalleles[grepl("Day 0",genotypedata_RR$Sample.ID),]
	recodedf[,(maxMOI*(j-1)+1) : (maxMOI*(j-1) + dim(newalleles)[2])] = newalleles[grepl("Day Failure",genotypedata_RR$Sample.ID),]

}

if (length(additional_neutral) > 0) { if (dim(additional_neutral)[1] > 0) {
recoded_additional_neutral = matrix(0,dim(additional_neutral)[1],maxMOI*nloci)
##### recode additional_neutral
for (j in 1:nloci) {
	locus = locinames[j]
	locicolumns = grepl(paste(locus,"_",sep=""),colnames(genotypedata_RR))
	oldalleles = as.vector(additional_neutral[,locicolumns])
	if (length(dim(oldalleles)[2]) == 0) {
		oldalleles = matrix(oldalleles,length(oldalleles),1)
	}
	newalleles = oldalleles
	ncolumns = dim(oldalleles)[2]
	for (i in 1:ncolumns) {
		newalleles[,i] = (sapply(1:dim(oldalleles)[1],function (x) recodeallele(alleles_definitions_RR[[j]],oldalleles[x,i])))
	}
	newalleles = matrix(as.numeric(unlist(c(newalleles))),dim(newalleles)[1],dim(newalleles)[2])
	newalleles[is.na(newalleles)] = 0
	oldalleles = matrix(as.numeric(unlist(c(oldalleles))),dim(oldalleles)[1],dim(oldalleles)[2])
	oldalleles[is.na(oldalleles)] = 0

	oldalleles[newalleles == 0] = 0
	recoded_additional_neutral[,(maxMOI*(j-1)+1) : (maxMOI*(j-1) + dim(oldalleles)[2])] = newalleles
}
} else {
	recoded_additional_neutral = c()
}}

## estimate frequencies

frequencies_RR = calculate_frequencies3(rbind(genotypedata_RR,additional_neutral),alleles_definitions_RR)

## assign random hidden alleles
for (i in 1:nids) {
	for (j in 1:nloci) {
		nalleles0 = sum(alleles0[i,(maxMOI*(j-1)+1) : (maxMOI*(j))] != 0)
		nmissing0 = MOI0[i] - nalleles0
		whichnotmissing0 = ((maxMOI*(j-1)+1) : (maxMOI*(j)))[which(alleles0[i,(maxMOI*(j-1)+1) : (maxMOI*(j-1)+MOI0[i])] != 0)]
		whichmissing0 = ((maxMOI*(j-1)+1) : (maxMOI*(j)))[which(alleles0[i,(maxMOI*(j-1)+1) : (maxMOI*(j-1)+MOI0[i])] == 0)]

		if (nalleles0 > 0) {
			hidden0[i,whichnotmissing0] = 0
		}
		if (nmissing0 > 0) {
			newhiddenalleles0 = sample(1:(frequencies_RR[[1]][j]),nmissing0,replace=TRUE,frequencies_RR[[2]][j,1:(frequencies_RR[[1]][j])])
			recoded0[i,whichmissing0] = newhiddenalleles0
			alleles0[i,whichmissing0] = rowMeans(alleles_definitions_RR[[j]])[newhiddenalleles0] # hidden alleles get mean allele length
			hidden0[i,whichmissing0] = 1
		}
		nallelesf = sum(allelesf[i,(maxMOI*(j-1)+1) : (maxMOI*(j))] != 0)
		nmissingf = MOIf[i] - nallelesf
		whichnotmissingf = ((maxMOI*(j-1)+1) : (maxMOI*(j)))[which(allelesf[i,(maxMOI*(j-1)+1) : (maxMOI*(j-1)+MOIf[i])] != 0)]
		whichmissingf = ((maxMOI*(j-1)+1) : (maxMOI*(j)))[which(allelesf[i,(maxMOI*(j-1)+1) : (maxMOI*(j-1)+MOIf[i])] == 0)]

		if (nallelesf > 0) {
			hiddenf[i,whichnotmissingf] = 0
		}
		if (nmissingf > 0) {
			newhiddenallelesf = sample(1:(frequencies_RR[[1]][j]),nmissingf,replace=TRUE,frequencies_RR[[2]][j,1:(frequencies_RR[[1]][j])])
			recodedf[i,whichmissingf] = newhiddenallelesf
			allelesf[i,whichmissingf] = rowMeans(alleles_definitions_RR[[j]])[newhiddenallelesf] # hidden alleles get mean allele length
			hiddenf[i,whichmissingf] = 1
		}
	}
}

## initial estimate of q (probability of an allele being missed)
qq = mean(c(hidden0,hiddenf),na.rm=TRUE)

## initial estimate of dvect (likelihood of error in analysis)
dvect = rep(0,1+round(max(sapply(1:nloci,function (x) diff(range(c(alleles_definitions_RR[[x]])))))))
dvect[1] = 0.75
dvect[2] = 0.2
dvect[3] = 0.05
## randomly assign recrudescences/reinfections
for (i in 1:nids) {
	z = runif(1)
	if (z < 0.5) {
		classification[i] = 1
	}
	for (j in 1:nloci) { # determine which alleles are recrudescing (for beginning, choose closest pair)
		allpossiblerecrud = expand.grid(1:MOI0[i],1:MOIf[i])
		closestrecrud = which.min(sapply(1:dim(allpossiblerecrud)[1], function (x) abs(alleles0[i,maxMOI*(j-1)+allpossiblerecrud[x,1]] - allelesf[i,maxMOI*(j-1)+allpossiblerecrud[x,2]])))
		mindistance[i,j] = abs(alleles0[i,maxMOI*(j-1)+allpossiblerecrud[closestrecrud,1]] - allelesf[i,maxMOI*(j-1)+allpossiblerecrud[closestrecrud,2]])
		alldistance[i,j,1:dim(allpossiblerecrud)[1]] = sapply(1:dim(allpossiblerecrud)[1], function (x) abs(alleles0[i,maxMOI*(j-1)+allpossiblerecrud[x,1]] - allelesf[i,maxMOI*(j-1)+allpossiblerecrud[x,2]]))
		allrecrf[i,j,1:dim(allpossiblerecrud)[1]] = recodedf[i,maxMOI*(j-1)+allpossiblerecrud[,2]]
		recr0[i,j] = maxMOI*(j-1)+allpossiblerecrud[closestrecrud,1]
		recrf[i,j] = maxMOI*(j-1)+allpossiblerecrud[closestrecrud,2]
		recr_repeats0[i,j] = sum(recoded0[i,(maxMOI*(j-1)+1) : (maxMOI*(j))] == recoded0[i,recr0[i,j]])
		recr_repeatsf[i,j] = sum(recodedf[i,(maxMOI*(j-1)+1) : (maxMOI*(j))] == recodedf[i,recrf[i,j]])
	}
}


#### correction factor (reinfection)
correction_distance_matrix = list() # for each locus, matrix of distances between each allele
for (i in 1:nloci) {
	correction_distance_matrix[[i]] = as.matrix(dist(rowMeans(alleles_definitions_RR[[i]])))
}


state_classification = matrix(NA,nids,(nruns-burnin)/record_interval)
state_alleles0 = array(NA,c(nids,maxMOI*nloci,(nruns-burnin)/record_interval))
state_allelesf = array(NA,c(nids,maxMOI*nloci,(nruns-burnin)/record_interval))
state_parameters = matrix(NA,2+2*nloci,(nruns-burnin)/record_interval)

count = 1
dposterior = 0.75
runmcmc = function() {
	# propose new classification
	# rellikelihood_reinfection = sapply(1:nids, function (x) (sum(log(frequencies_RR[[2]][cbind(1:nloci,recoded0[x,recrf[x,]])]))))
	#rellikelihood_recr = sapply(1:nids, function (x) (sum(log(dvect[round(mindistance[x,]+1)]))))
	# likelihoodratio = exp(rellikelihood_recr - rellikelihood_reinfection)
	# adjust for multiple corrections (ratio of multinomial coefficients)
	#likelihoodratio = sapply(1:nids, function (x) likelihoodratio[x]/exp(nloci*log(MOI0[x])+nloci*log(MOIf[x])-sum(log(recr_repeats0[x,]))-sum(log(recr_repeatsf[x,]))))
	#likelihoodratio = sapply(1:nids, function (x) exp(sum(log(sapply(1:nloci, function (y) mean(dvect[round(alldistance[x,y,])+1]/frequencies_RR[[2]][y,allrecrf[x,y,]],na.rm=TRUE))))))
	#likelihoodratio = sapply(1:nids, function (x) exp(sum(log(sapply(1:nloci, function (y) mean(dvect[round(alldistance[x,y,])+1]/colSums(frequencies_RR[[2]][y,1:frequencies_RR[[1]][y]]*matrix(dvect[correction_distance_matrix[[y]][,allrecrf[x,y,]]+1],frequencies_RR[[1]][y],frequencies_RR[[1]][y])),na.rm=TRUE))))))
	likelihoodratio = sapply(1:nids, function (x) exp(sum(log(sapply(1:nloci, function (y) mean(dvect[round(alldistance[x,y,])+1]/sapply(1:(maxMOI*maxMOI), function (z) sum(frequencies_RR[[2]][y,1:frequencies_RR[[1]][y]]*dvect[correction_distance_matrix[[y]][,allrecrf[x,y,z]]+1])),na.rm=TRUE))))))

	z = runif(nids)
	newclassification = classification
	newclassification[classification == 0 & z < likelihoodratio] = 1
	newclassification[classification == 1 & z < 1/likelihoodratio] = 0
	classification <<- newclassification
	
	# propose new hidden states
	sapply(1:nids, function (x) switch_hidden(x))
	
	# propose q (beta distribution is conjugate distribution for binomial process)
	q_prior_alpha = 0;
	q_prior_beta = 0;
	q_posterior_alpha = q_prior_alpha + sum(c(hidden0,hiddenf) == 1,na.rm=TRUE)
	q_posterior_beta = q_prior_beta + sum(c(hidden0,hiddenf)==0,na.rm=TRUE)
	if (q_posterior_alpha == 0) {
		q_posterior_alpha =1
	}
	qq <<- rbeta(1, q_posterior_alpha , q_posterior_beta)
	
	#  update dvect (approximate using geometric distribution)
	# only if there is at least 1 recrudescent infection
	if (sum(classification==1) >= 1) {
	d_prior_alpha = 0;
	d_prior_beta = 0;
	d_posterior_alpha = d_prior_alpha + length(c(mindistance[classification==1,]))
	d_posterior_beta = d_prior_beta + sum(c(round(mindistance[classification==1,])))
	if (d_posterior_beta == 0) {
		d_posterior_beta = sum(c((mindistance[classification==1,])))
	}
	if (d_posterior_beta == 0) { ## algorithm will get stuck if dposterior is allowed to go to 1
		d_posterior_beta = 1
	}	


	dposterior <<- rbeta(1, d_posterior_alpha , d_posterior_beta)
	dvect = (1-dposterior) ^ (1:length(dvect)-1) * dposterior
	dvect <<- dvect / (sum(dvect))
	}

	# update frequencies
	# remove recrudescing alleles from calculations
	tempdata = recoded0
	sapply(which(classification == 1), function (x) tempdata[x,recr0[x,]] <<- 0)
	tempdata = rbind(tempdata, recodedf)
	sapply(1:nloci, function (x) findposteriorfrequencies(x,rbind(tempdata,recoded_additional_neutral)))

	# record state
	if (count > burnin & count %% record_interval == 0) {
		print(count)
		state_classification[,(count-burnin)/record_interval] <<- classification
		state_alleles0[,,(count-burnin)/record_interval] <<- alleles0
		state_allelesf[,,(count-burnin)/record_interval] <<- allelesf
		state_parameters[1,(count-burnin)/record_interval] <<- qq
		state_parameters[2,(count-burnin)/record_interval] <<- dposterior
		state_parameters[3:(3+nloci-1),(count-burnin)/record_interval] <<- apply(frequencies_RR[[2]],1,max)
		state_parameters[(3+nloci):(3+2*nloci-1),(count-burnin)/record_interval] <<- sapply(1:nloci,function (x) sum(frequencies_RR[[2]][x,]^2))

	}
	count <<- count + 1
}

replicate(nruns,runmcmc())

## make sure no NAs in result matrices
state_parameters = state_parameters[,!is.na(colSums(state_parameters))]
state_classification = state_classification[,!is.na(colSums(state_classification))]

## find mode of hidden alleles
modealleles = matrix("",2*nids,maxMOI*nloci)
for (i in 1:nids) {
	for (j in 1:nloci) {
		modealleles[2*(i-1)+1,((j-1)*maxMOI+1):(j*maxMOI)] = sapply(1:maxMOI, function (x) names(table(state_alleles0[i,(j-1)*maxMOI+x,]))[table(state_alleles0[i,(j-1)*maxMOI+x,])== max(table(state_alleles0[i,(j-1)*maxMOI+x,]))][1])
		modealleles[2*(i-1)+2,((j-1)*maxMOI+1):(j*maxMOI)] = sapply(1:maxMOI, function (x) names(table(state_allelesf[i,(j-1)*maxMOI+x,]))[table(state_allelesf[i,(j-1)*maxMOI+x,])== max(table(state_allelesf[i,(j-1)*maxMOI+x,]))][1])
	}
}

rowMeans2 = function(x){
	if (length(dim(x)) == 0) {
		ret = mean(x)
	} else {
		ret = rowMeans(x)
	}
	ret
}

temp_combined = c(sapply(1:length(ids), function (x) rep(rowMeans2(state_classification)[x],2)))
outputmatrix = cbind(temp_combined,modealleles)
colnames(outputmatrix) = c("Prob Rec",c(sapply(1:nloci, function (x) paste(locinames[x],"_",1:maxMOI,sep=""))))
write.csv(outputmatrix,paste(jobname,"_posterior",".csv",sep=""))


# summary statistics of parameters
write.csv(state_parameters,paste(jobname,"_state_parameters",".csv",sep=""))

summary_statisticsmatrix = cbind(format(rowMeans(state_parameters),digits=2),
					   apply(format(t(sapply(1:dim(state_parameters)[1], function (x) quantile(state_parameters[x,],c(0.25,0.75)))),digits=2),1, function (x) paste(x,collapse="�")))
summary_statisticsmatrix = rbind(summary_statisticsmatrix, c(format(mean(state_parameters[(3+nloci):(3+2*nloci-1),]),digits = 2),paste(format(quantile(state_parameters[(3+nloci):(3+2*nloci-1),],c(0.25,0.75)),digits=2),collapse="�")))
summary_statisticsmatrix = as.matrix(sapply(1:dim(summary_statisticsmatrix)[1], function (x) paste(summary_statisticsmatrix[x,1], " (",summary_statisticsmatrix[x,2],")",sep="")))
rownames(summary_statisticsmatrix) = c("q","d",locinames,locinames,"Mean diversity")
write.csv(summary_statisticsmatrix,paste(jobname,"_summarystatistics",".csv",sep=""))
