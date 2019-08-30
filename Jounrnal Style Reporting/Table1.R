# Reporting table 1 in journal style
# Reporting categorical columns as N(%) and contiunous columns as mean(SD)

catcol = c('status', 'CAN_GENDER', 'race', 'CAN_PRELIM_XMATCH_REQUEST', 'ventilator_ecmo', 'CAN_CARDIAC_SURG',
           'payment', 'COPD_IPF', 'ABO')
numcol = c('CAN_AGE_AT_LISTING', 'CAN_HGT_CM', 'CAN_BMI', 'CAN_AT_REST_O2', 'art_mean')
f_cat = function(col, cond){
  tmp = cand1 %>% filter(proc_type == cond)
  if(col %in% catcol){
    a = table(droplevels(tmp[col]))
    b = round(prop.table(a)*100, 1)
    p = format.pval(chisq.test(table(cand1[[col]], cand1[['proc_type']]))$p.value, 3, 0.001)
    df = data.frame(a) %>%
      left_join(data.frame(b) %>% rename(Pct=Freq), by='Var1') %>%
      rename(name=Var1) %>%
      mutate(es_cl = paste0(Freq, ' (', Pct, ')'),
             name = paste0(!!col, ': ', name)) %>%
      select(-c(Freq, Pct))
  }
  if(col %in% numcol){
    es = colMeans(tmp[col])
    sd = sqrt(var(tmp[col]))
    p = format.pval(kruskal.test(as.formula(paste0(col, '~proc_type')), data=cand1)$p.value, 3, 0.001)
    df = data.frame(name = col, 
                    es_cl = paste0(round(es, 1), ' (', round(sd, 1), ')'))
  }
  if(cond=='Either'){
    df = df %>% mutate(pval=ifelse(row_number()==1, p, ''))
  }
  return(df)
}

# Here is the output
#                           name      Single      Double       Either   pval
# 1                             n        3146        4971         4151       
# 2                     status: C  461 (14.7) 1033 (20.8)   880 (21.2) <0.001
# 3                   status: D/R   268 (8.5)  587 (11.8)   426 (10.3)       
# 4                     status: T 2417 (76.8) 3351 (67.4)  2845 (68.5)       
# 5                 CAN_GENDER: M 2062 (65.5) 3025 (60.9)    2450 (59) <0.001
# 6                 CAN_GENDER: F 1084 (34.5) 1946 (39.1)    1701 (41)       
# 7                   race: White 2780 (88.4) 4107 (82.6)  3547 (85.4) <0.001
# 8                   race: Black   110 (3.5)   460 (9.3)    279 (6.7)       
# 9                race: Hispanic   172 (5.5)     298 (6)    233 (5.6)       
# 10                  race: Other    84 (2.7)   106 (2.1)     92 (2.2)       
# 11 CAN_PRELIM_XMATCH_REQUEST: N 2997 (95.3) 4730 (95.2)  3917 (94.4)  0.136
# 12 CAN_PRELIM_XMATCH_REQUEST: Y   149 (4.7)   241 (4.8)    234 (5.6)       
# 13           ventilator_ecmo: 0 3111 (98.9) 4792 (96.4)  4001 (96.4) <0.001
# 14           ventilator_ecmo: 1    35 (1.1)   179 (3.6)    150 (3.6)       
# 15          CAN_CARDIAC_SURG: N 2802 (89.1) 4782 (96.2)  3947 (95.1) <0.001
# 16          CAN_CARDIAC_SURG: U    41 (1.3)    62 (1.2)     52 (1.3)       
# 17          CAN_CARDIAC_SURG: Y   303 (9.6)   127 (2.6)    152 (3.7)       
# 18              payment: Public   1668 (53) 2053 (41.3)  1894 (45.6) <0.001
# 19             payment: Private 1454 (46.2) 2879 (57.9)  2225 (53.6)       
# 20          payment: Self/Other    24 (0.8)    39 (0.8)     32 (0.8)       
# 21               COPD_IPF: COPD 1054 (33.5) 2316 (46.6)  1683 (40.5) <0.001
# 22                COPD_IPF: IPF 2092 (66.5) 2655 (53.4)  2468 (59.5)       
# 23                       ABO: O 1429 (45.4) 2242 (45.1)  1904 (45.9)  0.612
# 24                       ABO: A 1292 (41.1) 1983 (39.9)  1648 (39.7)       
# 25                      ABO: AB   111 (3.5)   195 (3.9)    163 (3.9)       
# 26                       ABO: B    314 (10)  551 (11.1)   436 (10.5)       
# 27           CAN_AGE_AT_LISTING  64.2 (6.1)    57.9 (8)   60.4 (6.9) <0.001
# 28                   CAN_HGT_CM 170.7 (9.6) 170.4 (9.8) 169.7 (10.2) <0.001
# 29                      CAN_BMI    26.6 (4)  26.1 (4.4)   26.3 (4.3) <0.001
# 30               CAN_AT_REST_O2     4 (3.3)   4.8 (4.3)    4.6 (4.2) <0.001
# 31                     art_mean  22.4 (6.8) 26.7 (10.2)   23.2 (7.4) <0.001
