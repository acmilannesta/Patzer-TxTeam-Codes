**************************************************************************************************

SAS code for cumulative incidence curves

***************************************************************************************************;


*To get CI's, use CONFBAND=EP;

proc lifetest data=outcome3 method=pl outs=outproc noprint;
time time_tx*event_tx(0);
strata hosp_total_days_cat;
run;

data km;
set outproc;
percent=(1-survival)*100;
advyrs=time_tx/365.25;
keep hosp_total_days_cat percent advyrs;
run;

goptions reset=all;
proc gplot;
plot percent*advyrs = hosp_total_days_cat / haxis=axis1 vaxis=axis2;
symbol1 color=black width=2 i=j line=1;
symbol2 color=blue width=2 i=j line=2;
symbol3 color=green width=2 i=j line=33;
symbol4 color=red width=2 i=j line=34;
axis1 label=('time since listing (years)') order=(0 to 12 by 1);
axis2 label=(angle=90 '% transplanted') order=(0 to 100 by 20);
title 'Cumulative incidence plot of waitlist outcome by early waitlist hospitalization';
format hosp_total_days_cat hosp_total_days_cat.;
run;

