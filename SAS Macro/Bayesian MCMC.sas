
**************************************************************************************************
Tutorial 2: Bayesian MCMC
Author: Zhensheng Wang
Date: 02/25/2019

Data source:
The Sashelp.BirthWgt data set contains 50,000 random observations about infant birth weight in 2003 
from the US National Center for Health Statistics.

**************************************************************************************************;
data bweight;
  set sashelp.bweight;
run;


proc genmod data=Bweight;
  model weight = black boy CigsPerDay/dist=normal;
run;

DATA PRIOR;INPUT _TYPE_ $ black boy CigsPerDay;
DATALINES;
Mean -150 0 0  
Var  10 1e6 1e6
;
run;

proc genmod data=Bweight;
  bayes seed=890123 
		nbi=1000 
		nmc=10000 
		coeffprior=normal(input=prior) 
		plots=(trace autocorr) 
		stats(percent=2.5 50 97.5);
  model weight = black boy CigsPerDay/dist=normal;
run;
