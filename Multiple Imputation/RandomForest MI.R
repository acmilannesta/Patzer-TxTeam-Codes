library(dplyr)
library(ranger)
library(missRanger)
library(parallel)
library(pbapply)

# Based on a fast-implementation of random-forest algorithm to multiple impute missing values using chain equation (MICE)


# Checking missing cols
miss = data.frame(apply(cand1, 2, function(x) sum(is.na(x))))
colnames(miss)='n_miss'
misscols = row.names(miss)[miss$n_miss>0]
# CAN_HGT_CM                                                        13
# CAN_BMI                                                           14
# CAN_AT_REST_O2                                                  2897
# art_mean                                                         401


# parallel processing
cl = makeCluster(detectCores()/2)     # defining number of cores, for optimal performance using total number of cores/2
clusterEvalQ(cl, library(missRanger)) # loading package for each core
clusterExport(cl, 'cand1')            # loading global objects for each core

# progess bar list apply function
# call missRanger imputaton five times with a different seed number for each run
# NOTE: change your categorical variables with missing to factors using as.factor()
rf = pblapply(1:5, function(x) missRanger(formula=.~.-PERS_ID-status-futime-proc_type1, data = cand1, seed = x, pmm.k = 5), cl=cl)

# stop cluster to release occupied RAM
stopCluster(cl)
gc()

# combine five imputed datasets (average continous variables, and vote for categorical variables)
cand1 = rbindlist(rf) %>%
  group_by(PERS_ID) %>%
  mutate_at(misscols, mean) %>%
  mutate_at(c('race', 'payment'), function(x) names(which(table(x)==max(table(x))))[1]) %>%
  distinct(PERS_ID, .keep_all = T)
