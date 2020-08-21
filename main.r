## set working folder
setwd("\\\\cdc.gov\\private\\M326\\wif7\\Microsatellite\\GATech\\MRE")

library(gtools)


# user inputs
inputfile = "Angola2017_example.xlsx"
locirepeats = c(2,2,3,3,3,3,3)
nruns = 1000


# call script to import data
source("Import_Microsatellite_Data.R")


# calculate burnin (number of runs to discard) and record interval (which n_th iterations should be recorded)
record_interval = ceiling(nruns / 1000);
burnin = ceiling(nruns * 0.25);
source("run_all_arms.r")

