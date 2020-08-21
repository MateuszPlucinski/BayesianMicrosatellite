### identify arms (based on site column)

site_names = unique(genotypedata_latefailures$Site)

state_classification_all = c()
state_parameters_all = c()
ids_all = c()

for (site in site_names) {
	jobname = site
	genotypedata_RR = genotypedata_latefailures[genotypedata_latefailures$Site==site,-c(2)]
	additional_neutral = additional_genotypedata[additional_genotypedata$Site==site,-c(2)]
	if (dim(additional_neutral)[1] > 0) { additional_neutral$Sample.ID = paste("Additional_",1:dim(additional_neutral)[1],sep="")}
	source("mcmc.r")

	state_classification_all = rbind(state_classification_all,state_classification)
	state_parameters_all = rbind(state_parameters_all,state_parameters)
	ids_all = c(ids_all,ids)
}

rowMeans2 = function(x){
  if (length(dim(x)) == 0) {
    ret = mean(x)
  } else {
    ret = rowMeans(x)
  }
  ret
}

cbind2 = function(y,x){
  if (length(dim(x)) == 0) {
    ret = c(y,x)
  } else {
    ret = cbind(y,x)
  }
  ret
}

posterior_distribution_of_recrudescence = rbind(cbind2(ids_all,(state_classification_all)))
colnames(posterior_distribution_of_recrudescence)[1] = "ID"

probability_of_recrudescence = rowMeans2(state_classification_all)

hist(probability_of_recrudescence,breaks=10,main="Distribution of posterior probability of recrudescence",xlab="Posterior probability of recrudescence")

write.csv(posterior_distribution_of_recrudescence,"microsatellite_correction.csv",row.names=FALSE)
write.csv(probability_of_recrudescence ,"probability_of_recrudescence.csv",row.names=FALSE)