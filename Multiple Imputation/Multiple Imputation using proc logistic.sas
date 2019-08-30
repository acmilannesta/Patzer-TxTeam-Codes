* Example Multiple Imputation Code - PROC LOGISTIC;

proc mi data=imputedall2 out=finalimputation seed=8675309 nimpute=5;
class caco edu complparity durationbf;
fcs logistic;
var caco edu MAAM prepregBMI matagedeliv complparity birthwt durationbf
BMIZ Sample_Gestation ETL2 ETL3;
run;
 
proc logistic data=finalimputation descending;
class caco complparity durationbf edu;
model caco = ETL2 ETL3 MAAM prepregBMI complparity durationBF edu Sample_Gestation/ covb;
by _imputation_;
ods output parameterestimates = final_METL CovB=lgscovb;
run;
 
proc mianalyze parms(classvar=classval)=final_METL;
class caco complparity durationbf edu;
modeleffects intercept ETL2 ETL3 MAAM prepregBMI complparity durationBF edu Sample_Gestation ;
run;
