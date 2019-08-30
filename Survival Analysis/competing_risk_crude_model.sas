libname dfwl "C:\Users\zhangxyu\Desktop\JAMA_paper_revision\new_cohort";
options nofmterr;

data dfwl.fortable3;
set dfwl.pat_facility_dfc17;
if edate ne '' then wl=1; else wl=0;
if ldtxdate ne '' then livingd=1; else livingd=0;
if wl=1 or livingd=1 then combine=1;  else combine=0;
if TX1DONOR='C' and TX1DATE ne . then deceasedt=1;else deceasedt=0;
if TX1DONOR='C' and TX1DATE ne . then dectime=TX1DATE;
wl_time=(min(edate,died,MDY(12,31,2016))-first_se+1)/30.4375;
wlist=(min(edate,died,MDY(12,31,2016))=edate); 
if edate=. and 0<died<MDY(12,31,2016) then wlist=2;
dec_time=(min(dectime,died,MDY(12,31,2016))-first_se+1)/30.4375;
dec=(min(dectime,died,MDY(12,31,2016))=dectime); 
if dectime=. and 0<died<MDY(12,31,2016) then dec=2;


ld_time=(min(ldtxdate,died,MDY(12,31,2016))-first_se+1)/30.4375;
ldtx=(min(ldtxdate,died,MDY(12,31,2016))=ldtxdate); 
if ldtxdate=. and 0<died<MDY(12,31,2016) then kdtx=2;

wl_ld_time=(min(edate, ldtxdate,died,MDY(12,31,2016))-first_se+1)/30.4375;
wl_ldtx=(min(edate, ldtxdate,died,MDY(12,31,2016))=min (ldtxdate,edate));


run;

data fortable3;
set dfwl.fortable3;
keep wl_time wlist ld_time ldtx wl_ld_time wl_ldtx dec_time dec
chain_class2 sex_new	age_cat	esrd_cause	race_new	insurance_esrd	
bmi_35 	ashd_new	chf	other_cardiac	cva_new	pvasc_new	hypertension	diabetes	
copd_new	smoke_new	cancer_new	nephcare_cat pt_notinformed_MED_dfr
Mortality_Rate_Facility Hospitalization_Rate_facility socialwkr_dfr survtime provusrd;
run;

proc stdize reponly method=median data=fortable3 out=fortable3_2;
var chain_class2	sex_new	age_cat	race_new 
esrd_cause		bmi_35 	ashd_new	chf	other_cardiac	cva_new	pvasc_new	hypertension	diabetes	
copd_new	smoke_new	cancer_new insurance_esrd nephcare_cat pt_notinformed_MED_dfr
Mortality_Rate_Facility Hospitalization_Rate_facility socialwkr_dfr survtime ;
run;

proc surveyselect data = fortable3_2 out = fortable3_3 method = srs samprate = .1 seed = 9876;
run;


proc phreg data=fortable3_3;
class 	chain_class2 (ref='5') ;
model wl_time*wlist(0) = chain_class2	/rl eventcode=1 ;
id provusrd;
run;

proc phreg data=fortable3_3 ;
class 	chain_class2 (ref='5') ;
model ld_time*ldtx(0) = chain_class	/rl eventcode=1 ;
id provusrd;
run;

proc phreg data=fortable3_3  ;
class 	chain_class2 (ref='5') ;
model dec_time*dec(0) = chain_class	/rl eventcode=1 ;
id provusrd;
run;
