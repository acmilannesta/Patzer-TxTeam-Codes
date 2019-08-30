pkg_need = c('dplyr',
             'parallel',
             'sas7bdat',
             'data.table', 
             'haven')

for(pkg in pkg_need){
  if(!(require(pkg, character.only = T))){
    install.packages(pkg)
  }
  library(pkg, character.only = T)
}

# load required datafiles
pat = fread('patients.csv', header=T, sep=',')
rxhist = fread('rxhist.csv', header=T, sep=',')
rxhist60 = fread('rxhist60.csv', header=T, sep=',')
cwalk = read_sas('xref_prv_2017.sas7bdat') %>% mutate(PROVUSRD=as.integer(PROVUSRD))
wlki = fread('waitlist_ki.csv', header=T, sep=',')
death = fread('death.csv', header=T, sep=',', fill = T)
facility = fread('facility.csv', header=T, sep=',')
medevid = fread('medevid.csv', header=T, sep=',')
ref1217 = read_sas('refeval_1217.sas7bdat') %>% mutate(person_id=as.integer(person_id))
duacwalk = fread('Dua201617_crosswalk.csv', header=T, sep=',')
# ascent = read.csv('ascent.extended.ind.clust.csv')
# ref18 = read.csv('Referral Data_2014-2018_7.22.19_Raw Data.csv')
ncc = fread('NCC_census.csv', header=T, sep=',')
ref1217 = read_sas('refeval_1217.sas7bdat')



###########################################
# Part I. USRDS data cleaning
###########################################

# manipulate on individual datasets
rxhist60_1 = rxhist60 %>%
  filter(BEGDAY==1) %>%
  left_join((rxhist %>% dplyr::select(USRDS_ID, BEGDATE, PROVUSRD)), by=c('USRDS_ID', 'BEGDATE')) %>%
  filter(!is.na(PROVUSRD)) %>%
  left_join(cwalk, by='PROVUSRD')

wlki_1 = wlki %>%
  dplyr::select(USRDS_ID, EDATE) %>%
  filter(!is.na(USRDS_ID)) %>%
  arrange(USRDS_ID, as.Date(EDATE, '%m/%d/%Y')) %>%
  distinct(USRDS_ID, .keep_all = T)

medevid_1 = medevid %>%
  dplyr::select(TYPE2728, USRDS_ID, CRDATE, PDIS, ETHN, ALBUM, HEGLB, EPO, starts_with('MEDCOV'),
         starts_with('COMO'), BMI, NEPHCARE, DIALDAT, PATINFORMED, starts_with('PATTXOP'),
         ACCESSTYPE, AVFMATURING, AVGMATURING) %>%
  arrange(USRDS_ID, desc(as.Date(CRDATE, '%m/%d/%Y'))) %>%
  distinct(USRDS_ID, .keep_all = T)

facility_1 = facility %>%
  filter(between(FS_YEAR, 2012, 2016)) %>%
  mutate(facility_nopatients_start = BEG_TOT,
         facility_nopatients_end = END_TOT,
         facility_profitstatus = ifelse(NU_P_NP=="For-profit", 1, 0),
         facility_type =ifelse(NU_HBFS==2, 1, 0),
         facility_numsw = HSWFT+0.5*HSWPT,
         facility_swratio = END_TOT/(HSWFT+0.5*HSWPT)) %>%
  arrange(PROVUSRD, FS_YEAR) %>%
  distinct(PROVUSRD, .keep_all = T)


# merge on master patient file
pat1 = pat %>%
  filter(ADRIND ==1 & 
           between(as.Date(FIRST_SE, '%m/%d/%Y'), as.Date('2012/01/01'), as.Date('2016/08/31'))) %>%
  left_join(rxhist60_1, by='USRDS_ID') %>%
  filter(!is.na(PROVUSRD)) %>%
  mutate(facility = ifelse(substr(PROVHCFA, 1, 2) %in% c('11', '85'), 1,
                           ifelse(substr(PROVHCFA, 1, 2) %in% c('34', '86'), 2,
                                  ifelse(substr(PROVHCFA, 1, 2) %in% c('42', '87'), 3, NA))),
         preempt_tx=ifelse(RXGROUP=='T', 1, 0)) %>%
  filter(!is.na(facility) &
           RXGROUP %in% c("1", "2", "3", "5", "7", "9", "T") &
          between(INC_AGE, 18, 80)) %>%
  left_join(wlki_1, by='USRDS_ID') %>%
  # filter(!(as.Date(FIRST_SE, '%m/%d/%Y')>as.Date(EDATE,'%m/%d/%Y') & !is.na(EDATE))) %>%
  left_join(death[!is.na(death$USRDS_ID),], by='USRDS_ID') %>%
  mutate(death_date = pmin(as.Date(DOD, '%m/%d/%Y'), as.Date(DIED, '%m/%d/%Y'), na.rm = T)) %>%
  left_join(medevid_1, by='USRDS_ID') %>%
  left_join(facility_1, by='PROVUSRD')


###########################################
# Part II. Referral data cleaning
###########################################
duacwalk_1 = duacwalk %>%
  select(USRDS_ID, PTID) %>%
  rename(person_id = PTID)

ref = ref1217 %>%
  filter(between(as.Date(referral_date), as.Date('2012/01/01'), as.Date('2017/08/31')) &
           !is.na(person_id)) %>%
  inner_join(duacwalk_1, by='person_id') %>%
  arrange(USRDS_ID, as.Date(referral_date), as.Date(evaluation_start_date)) %>%
  distinct(USRDS_ID, dialysis_start_date, referral_date, dialysis_facility_ccn, .keep_all = T) %>%
  group_by(USRDS_ID) %>%
  mutate(total_referrals = n()) %>%
  slice(1) %>%
  ungroup %>%
  select(USRDS_ID ,person_id ,txcenter_id,dialysis_start_date ,dialysis_facility_name ,dialysis_facility_address,
         dialysis_facility_city ,dialysis_facility_state ,dialysis_facility_zip_code ,dialysis_facility_ccn ,
         preemptive_referral ,referral_date ,evaluation_start_date ,evaluation_completion_date,
         waitlisting_date ,referring_physician_name ,referring_physician_phone ,total_referrals)


###########################################
# Part III. Referral data, USRDS denomiator file and ASCENT data merging
###########################################  
ref_pat = pat1 %>%
  left_join(ref, by='USRDS_ID') %>%
  mutate(facility_swratio = ifelse(facility_swratio==Inf, 0, facility_swratio),
         ccn = sub('^[0]+','', PROVHCFA),
         prempt = ifelse(!is.na(as.Date(referral_date)) & as.Date(referral_date)<as.Date(FIRST_SE, '%m/%d/%Y'), 1, 0)) %>%
  left_join(ncc %>% mutate(PROVHCFA=as.character(PROVHCFA)) %>% distinct(PROVHCFA,.keep_all=T), by='PROVHCFA') %>%
  filter(prempt==0 &
        !grepl('F$', PROVHCFA) &
        is.na(CTR_CD_FLAG) &
        Total_avg_ex0>=10.45
        )  %>% 
   mutate(referred = ifelse (!is.na(referral_date), 1, 0)) %>%
   mutate(ref_1yr = ifelse(referred==1 &
                             pmin(as.Date(TX1DATE, '%m/%d/%Y'), 
                                # as.Date(EDATE, '%m/%d/%Y'),
                                as.Date(death_date, '%m/%d/%Y'), 
                                as.Date(referral_date), na.rm = T) == as.Date(referral_date) &
                             between(as.Date(referral_date), 
                                     as.Date(FIRST_SE, '%m/%d/%Y'), 
                                     as.Date(FIRST_SE, '%m/%d/%Y')+365.25, incbounds = T), 1, 0)) %>%
   mutate(eval_6mo = ifelse(is.na(evaluation_start_date), 0,
                          ifelse(ref_1yr==1 &
                          pmin(as.Date(TX1DATE, '%m/%d/%Y'), 
                               # as.Date(EDATE, '%m/%d/%Y'),
                               as.Date(death_date, '%m/%d/%Y'), 
                               as.Date(evaluation_start_date), na.rm = T) == as.Date(evaluation_start_date) &
                          between(as.Date(evaluation_start_date), 
                                  as.Date(referral_date), 
                                  as.Date(referral_date)+180, incbounds = T), 1, 0)))

# write.csv(ref_pat, 'refeval_080819.csv', row.names = F)


