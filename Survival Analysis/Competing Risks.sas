

data competing_risks;
set survival_analysis_waitlist;
*Recoding event to allow more than one outcome - here it is 0 (censored), 1 (dead), or 2 (transplanted);
if can_rem_CD = . then multi_state_event = 0;
else if can_rem_CD = 5 or can_rem_CD = 8 or can_rem_CD = 13 then multi_state_event = 1;
else if can_rem_CD = 4 or can_rem_CD = 14 or can_rem_CD = 15 or can_rem_CD = 18 or can_rem_CD = 22 then multi_state_event = 2;
else multi_state_event = 0;
if can_rem_CD = . then multi_survtime = '31Dec2014'd - CAN_LISTING_DT;
else multi_survtime = CAN_REM_DT - CAN_LISTING_DT;
run;
 

 
 
 
proc phreg data=competing_risks covsandwich(aggregate);
class CHI_cat (ref = first);
model multi_survtime*multi_state_event(0)/*0 is the censored value*/ = init_meld CHI_cat / eventcode=1;
/*Eventcode is what tells SAS to do a competing risks model - put event of interest after equals sign (here it is mortality, but if it were transplant it
would be eventcode = 2)*/
id region;
hazardratio 'Subdistribution Hazard Ratios' CHI_cat / diff=pairwise;
run;
