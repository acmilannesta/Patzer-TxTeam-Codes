# Powerful Dplyr package allowing for data manipulation (merging, selecting rows/columns, sorting, keep distincet, create new columns, 
# and a whole bunch more) in one chained pipeline by "%>%".

library(dplyr)
library(haven)

cand = read_sas('cand_thor.sas7bdat')

cand1 = cand %>%
  filter(WL_ORG=='LU' & 
         between(CAN_LISTING_DT, 
                 as.Date('2006/01/01'),
                 as.Date('2015/12/31')) &
           CAN_AGE_AT_LISTING>=18 &
           CAN_DGN %in% c(1604, 1607)) %>%
  arrange(PERS_ID, desc(CAN_LISTING_DT)) %>%
  distinct(PERS_ID, .keep_all = T) %>%
  mutate(status = case_when(REC_TX_DT-CAN_LISTING_DT<=365.25~'T',
                            CAN_REM_CD %in% c(8, 13) & CAN_REM_DT-CAN_LISTING_DT<=365.25~'D/R',
                            T~'C'),
         futime = as.numeric(pmin(REC_TX_DT,
                                  CAN_REM_DT, 
                                  CAN_LAST_ACT_STAT_DT,
                                  na.rm = T)-CAN_LISTING_DT)/(365.25/12),
         race = relevel(factor(case_when(CAN_RACE==8~'White',
                          CAN_RACE==16~'Black',
                          CAN_RACE==2000~'Hispanic',
                          T~'Other')), 'White'),
         COPD_IPF = factor(case_when(CAN_DGN==1607~'COPD',
                              CAN_DGN==1604~'IPF')),
         ABO = relevel(factor(case_when(CAN_ABO %in% c('A', 'A1', 'A2')~'A',
                         CAN_ABO %in% c('B')~'B',
                         CAN_ABO %in% c('O')~'O',
                         CAN_ABO %in% c('AB', 'A1B', 'A2B')~'AB')), 'O'),
         art_mean = CAN_PULM_ART_SYST/3+2/3*CAN_PULM_ART_DIAST,
         ventilator_ecmo  = as.numeric(CAN_VENTILATOR==1|CAN_ECMO==1),
         payment = relevel(factor(case_when(CAN_PRIMARY_PAY==1~'Private',
                             CAN_PRIMARY_PAY %in% c(seq(2, 7), 13)~'Public',
                             T~'Self/Other')), 'Public'),
         proc_type = factor(case_when((CAN_LF_LU_PREF_FLG==1 | CAN_RT_LU_PREF_FLG==1) & CAN_BOTH_LU_PREF_FLG==0~'Single',
                               CAN_LF_LU_PREF_FLG==0 & CAN_RT_LU_PREF_FLG==0 & CAN_BOTH_LU_PREF_FLG==1~'Double',
                               (CAN_LF_LU_PREF_FLG==1 | CAN_RT_LU_PREF_FLG==1) & CAN_BOTH_LU_PREF_FLG==1~'Either',
                               is.na(CAN_LF_LU_PREF_FLG) ~NA_character_)),
         proc_type1 = factor(case_when(CAN_LF_LU_PREF_FLG==1 & CAN_BOTH_LU_PREF_FLG==0~'Left',
                                        CAN_RT_LU_PREF_FLG==1 & CAN_BOTH_LU_PREF_FLG==0~'Right',
                                      CAN_LF_LU_PREF_FLG==0 & CAN_RT_LU_PREF_FLG==0 & CAN_BOTH_LU_PREF_FLG==1~'Double',
                                      (CAN_LF_LU_PREF_FLG==1 | CAN_RT_LU_PREF_FLG==1) & CAN_BOTH_LU_PREF_FLG==1~'Either',
                                      is.na(CAN_LF_LU_PREF_FLG) ~NA_character_)),
         CAN_GENDER = relevel(factor(CAN_GENDER), 'M'),
         CAN_PRELIM_XMATCH_REQUEST = factor(CAN_PRELIM_XMATCH_REQUEST),
         CAN_CARDIAC_SURG=factor(ifelse(CAN_CARDIAC_SURG=="", 'U', CAN_CARDIAC_SURG))) %>%
  select(PERS_ID, status, futime, CAN_AGE_AT_LISTING, CAN_GENDER,
         race, CAN_HGT_CM, CAN_PRELIM_XMATCH_REQUEST, CAN_BMI, ventilator_ecmo,
        CAN_CARDIAC_SURG, payment, proc_type, proc_type1, CAN_AT_REST_O2, COPD_IPF, ABO, art_mean)
