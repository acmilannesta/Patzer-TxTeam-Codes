
**************************************************************************************************
Tutorial 1: How to use SQL to run batch macro
Author: Zhensheng Wang
Date: 02/11/2019

Data source:
The Sashelp.BirthWgt data set contains 50,000 random observations about infant birth weight in 2003 
from the US National Center for Health Statistics.

**************************************************************************************************;
data bweight;
  set sashelp.bweight;
run;

proc contents data=bweight out=colname(keep=name) order=varnum;
run;

*************************************************
WAY 1: direct model statements
*************************************************;
title "Baby weight regressed on predictor: black";
proc reg data=bweight plots=none;
  model Weight = black;
quit;

title "Baby weight regressed on predictor: boy";
proc reg data=bweight plots=none;
  model Weight = boy;
quit;

title "Baby weight regressed on predictor: CigsPerDay";
proc reg data=bweight plots=none;
  model Weight = CigsPerDay;
quit;

*6 more to go...;

   **          **
********	********

	    ....

         /\
 		/  \

*************************************************
WAY 2: simple MACRO
*************************************************;

%macro regperform1(x);
	*selective output;
	ods select parameterestimates;

	*add a title (must use double quote to resolve macro variable);
	title "Baby weight regressed on &x.";

	*run the model;
	proc reg data=bweight plots=none;
	  model Weight = &x.;
	quit;

%mend;

%regperform1(x=black)
%regperform1(x=boy)
%regperform1(x=CigsPerDay)
%regperform1(x=married)
%regperform1(x=MomAge)
%regperform1(x=MomEdLevel)
%regperform1(x=MomSmoke)
%regperform1(x=MomWtGain)
%regperform1(x=Visit)




*************************************************
LET'S GET A BIT MORE SUCCINT!
WAY 3: SQL + MACRO
*************************************************;

*USE SQL to extract all variable names except "weight" (response) and store into macro variable "predictor";
proc sql noprint;
  select * into: predictor separated by ' '
  from colname
  where name ne "Weight";
quit;


%put &predictor;

%macro regperform2;
  %do i = 1 %to %sysfunc(countw(&predictor)); *countw(): count the length of macro list;

    %let x = %sysfunc(scan(&predictor, &i));  *extract element from the sas list;

	*selective output;
	ods select parameterestimates;

	*add a title (must use double quote to resolve macro variable);
	title "Baby weight regressed on &x.";

	*run the model;
	proc reg data=bweight plots=none;
	  model Weight = &x.;
	quit;

  %end;

%mend regperform2;

%regperform2


*************************************************
		another way for batch macro
*************************************************;

%macro regperform3(x);
  
	*selective output;
	ods select parameterestimates;

	*add a title (must use double quote to resolve macro variable);
	title "Baby weight regressed on &x.";

	*run the model;
	proc reg data=bweight plots=none;
	  model Weight = &x.;
	quit;

%mend regperform3;

data _null_;
  set colname(where=(name ne "Weight"));
  call execute('%nrstr(%regperform3(x='||strip(name)||'))');
run;


*************************************************
CAN GO EVEN FURTHER
WAY 4: SQL + MACRO + store parameters
*************************************************;
%macro regperform4;
  %do i = 1 %to %sysfunc(countw(&predictor)); *countw(): count the length of macro list;

    %let x = %sysfunc(scan(&predictor, &i));  *extract element from the sas list;

	*selective output;
	ods select parameterestimates;

	*add a title (must use double quote to resolve macro variable);
	title "Baby weight regressed on &x.";

	*run the model and output parameters;
	proc reg data=bweight plots=none;
	  model Weight = &x.;
	  ods output parameterestimates=tmp(keep=Variable Estimate StdErr Probt);
	quit;

	*if the first loop, save tmp file to master file;
	%if &i.=1 %then %do;
	data coef;
	  set tmp(where=(variable="&x."));
	run;
	%end;

	*otherwise stack up tmp file;
	%if &i.>1 %then %do;
	data coef;
	  set coef tmp(where=(variable="&x."));
	run;
	%end;

  %end;

%mend regperform4;

%regperform4

title 'Data with parameter estiamtes';
PROC PRINT DATA=COEF NOOBS;
RUN;


*************************************************
		GENERATE PUBLISHABLE DATA
*************************************************;
/*extract data for reporting table*/
proc sql;
  create table reporttbl as
  select variable 'Predictor' as predictor,
  		 put(Estimate, 5.1) 'Coefficient' as coef,
		 '('||strip(put(Estimate-1.96*StdErr, 5.1))||', '||strip(put(Estimate+1.96*StdErr, 5.1))||')' '95% CI' as ci,
		 put(Probt, pvalue5.3) 'P-value' as pval
  from coef;
quit;

/*generate elegant RTF report*/
options orientation=landscape leftmargin="0.1in" rightmargin="0.1in" nodate nonumber;
ods rtf file="g:\journal club\test report.rtf";
title "Linear Regression Estimates";
ods escapechar='^';
proc report data=reporttbl 
			nowd
			style(column)=[fontfamily=arial 
						   borderrightcolor=white 
						   borderbottomcolor=white 
						   just=center] 
			style(hdr)=[verticalalign=middle 
						fontfamily=arial 
						fontweight=bold 
					    bordertopwidth=2 
						borderbottomwidth=3  
						borderrightcolor=white 
						backgroundcolor=white]
			style(report)=[frame=void rule=none];
  column  ('^S={borderbottomcolor=white}' predictor)  ("OLS Estimates" coef ci pval);
  define predictor/group "Predictor";
  define coef/group "Coefficient^{super 1}" ;
  define ci/group "95% CI^{super 2}";
  define pval/group "P-value";
  compute after/style={just=l fontfamily=arial bordertopwidth=3 bordertopcolor=black};
    line "^{super 1} Estimate based on univariable model";
	line "^{super 2} CI: Confidence intervals";
  endcomp;
run;
ods rtf close;


proc glm data=sashelp.class plots=none;
  class sex;
  model height = sex age;
quit;
