
*in these examples, referral_to_waitlist is the time variable in days, listed_new is the outcome, and we are 
comparing intervention vs. control patients (study_group);

*first test the proportional hazards model with three methods;

*1 - schoenfeld residuals ;
proc phreg data=navigation2;
class study_group (ref='Control')/param=ref;
model referral_to_waitlist*listed_new(0)=study_group;
output out =sr_data ressch=sr_study_group;
run;


data failures_only;
set sr_data;
if listed_new = 1;
run;

proc rank data=failures_only out=ranked_failures ties=mean;
var referral_to_waitlist;
ranks timerank;
run;

proc corr data=ranked_failures nosimple;
var sr_study_group;
with timerank;
run;
*pearson correlation coefficients p=0.01 PH violated;
*if PH >0.05 PH not violated and you can do a normal Cox test;


*2- test PH assumption using log-log curves ;
proc lifetest data=navigation2 method=km plots=(s,lls);
time referral_to_waitlist*listed_new(0);
strata study_group;
run;
*lines cross - assumption is violated;
*if lines don't cross, you can use regular cox model;


*3 - test PH assumption using time dependent variable;
proc phreg data = navigation2;
model referral_to_waitlist*listed_new(0) = study_group study_group_time;
study_group_time = study_group*referral_to_waitlist;
run;
*p-value-0.02:  violated;
*if p>0.05 then can do regular cox model;


*cox model;
PROC PHREG data=navigation2;
class study_group (ref='Control')/param=ref;
model referral_to_waitlist*listed_new(0)=study_group/rl;
run;
*1.24;



*KM Curve;
proc lifetest data=navigation2 method=km plots=(s,lls);
time referral_to_waitlist*listed_new(0);
strata study_group;
run;
