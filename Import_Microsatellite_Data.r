memory.limit(size=50000)
options(java.parameters = "-Xmx4096m")

library(rJava)
library(gtools)
require(XLConnect)

##### read in data

excel_file <- loadWorkbook(inputfile)
genotypedata_latefailures = readWorksheet(excel_file, sheet = "Late Treatment Failures",startRow=4)
genotypedata_latefailures[genotypedata_latefailures == 0] = NA # missing data has to be coded as NA
genotypedata_latefailures[genotypedata_latefailures == "0"] = NA # missing data has to be coded as NA
genotypedata_latefailures[genotypedata_latefailures == "N/A"] = NA # missing data has to be coded as NA
genotypedata_latefailures[genotypedata_latefailures == "-"] = NA # missing data has to be coded as NA
genotypedata_latefailures[genotypedata_latefailures == "NA"] = NA # missing data has to be coded as NA

### recode sample names so that each pair has a " Day 0" and a " Day Failure"
genotypedata_latefailures$Sample.ID = sub("D0$"," Day 0",genotypedata_latefailures$Sample.ID)
genotypedata_latefailures$Sample.ID = sub("D[0-9]+$"," Day Failure",genotypedata_latefailures$Sample.ID)


# each sample in genotypedata_RR has to have day 0 and day of Failure
ids = unique(unlist(strsplit(genotypedata_latefailures$Sample.ID[grepl("Day 0",genotypedata_latefailures$Sample.ID)]," Day 0")))
if (sum(!paste(ids, "Day Failure") %in% genotypedata_latefailures$Sample.ID) > 0) {
	print("Error - each sample must have day 0 and day of failure data")
}
ids = unique(unlist(strsplit(genotypedata_latefailures$Sample.ID[grepl("Day Failure",genotypedata_latefailures$Sample.ID)]," Day Failure")))
if (sum(!paste(ids, "Day 0") %in% genotypedata_latefailures$Sample.ID) > 0) {
	print("Error - each sample must have day 0 and day of failure data")
}

### background samples (from "Additional" tab)
  additional_genotypedata = readWorksheet(excel_file, sheet = "Additional",startRow=4)
  if (dim(additional_genotypedata)[1] > 0) { 
    additional_genotypedata[additional_genotypedata == 0] = NA # missing data has to be coded as NA
    additional_genotypedata[additional_genotypedata == "0"] = NA
    additional_genotypedata[additional_genotypedata == "N/A"] = NA
    additional_genotypedata[additional_genotypedata == "-"] = NA
    additional_genotypedata[additional_genotypedata == "NA"] = NA
    additional_genotypedata$Sample.ID = sub("_D0"," Day 0",additional_genotypedata$Sample.ID)
    additional_genotypedata$Sample.ID = sub("_D[0-9]*"," Day Failure",additional_genotypedata$Sample.ID)
  }
  
  # recode as numeric
  genotypedata_latefailures[,colnames(genotypedata_latefailures)[-c(1,2)]] = sapply(colnames(genotypedata_latefailures)[-c(1,2)],function (x) as.numeric(as.character(genotypedata_latefailures[,x])))
  additional_genotypedata[,colnames(additional_genotypedata)[-c(1,2)]] = sapply(colnames(additional_genotypedata)[-c(1,2)],function (x) as.numeric(as.character(additional_genotypedata[,x])))
  