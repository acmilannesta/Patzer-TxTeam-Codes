* Program savesurv_T.sas ;
* Created by Nancy Cook (BWH, HMS, HSPH) ;
* Sample program to save survival probabilities at time T;
* Generated from Cox model;

**** Sample Program - Revise to fit your data ****;
data one; set data;
* set fake id for merge;
_id_=_n_;
* Define variables as:
  _id_ = identification variable (>0)
  outc = outcome (1=event, 0=censored)
  years = survival time
  x1-x20 = predictor variables (revise as needed)
  ;
run;

data two;
* Create dummy observation with time of T years (here=10);
_id_=0;
outc=.; years=10; 

*** Set all model variables (labelled x1-x20) to reference values;
* Here reference is set to 0 ;
* Check that 0 value makes sense for these vars;
* Revise as needed (eg, set age to some value>0);
array nullvars {*} x1-x20;
nvar=dim(nullvars);
do i=1 to nvar;
  nullvars(i)=0;
end;
drop nvar i;
output;
run;

data one; set one two;
proc sort data=one; by _id_;
run;


/******  MACRO DEFINITION  *******/

%macro PREDMAC (DSNAME, EVENT, EVNTLABL, PYRS, MODLABL, PROB);
   proc phreg data=&DSNAME outest=betas(drop=_ties_ _type_ _name_);
	   id _id_;
           model &PYRS*&EVENT(0)= &MODVARS  / rl;
           output out=survdat survival=survest xbeta=bx;
           title2 "PHREG for Outcome: &EVNTLABL";
           title3 "For Model = &MODLABL";
   run;

   data base; set survdat;
   * Keep dummy obs only;
     if _id_=0;
     * baseline survival estimate for referent person;
     basesurv=survest;
     * centered linear estimate;
     bxave=bx;
     keep basesurv bxave;
   put _id_= &pyrs= basesurv= bxave= ;

   data preddat; merge &DSNAME survdat; by _id_;
   * delete dummy obs;
     if _id_=0 then delete;
   data preddat; 
     if _n_=1 then set base;
     set preddat ;
     surv=basesurv**(exp(bx-bxave));
     &prob=1-surv;
     run;

   proc univariate plot data=preddat; id _id_;
     var &prob;
     title2 "Predicted Event Probabilities from Cox Model";
     title3 "For Outcome = &EVNTLABL and Model = &MODLABL ";
   run;
%mend PREDMAC;
* EXAMPLE USAGE OF MACROS;
* %predmac(one, cvd, Total CVD, pyrs, Model with X1-X20, prcvd10);

/******  END MACRO DEFINITION  *******/


%let MODVARS = x1-x20 ;
%PREDMAC (one, outc, Outcome Label, years, Model Label, probt);
run;

*** Save dataset preddat ***;
* probt = predicted risk at time T;
/* Set output directory in libname statement;
data out.data2; set preddat;
*/
