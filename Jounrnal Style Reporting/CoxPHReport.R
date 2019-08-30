# Report PH Cox model in journal style
# HR (95% CI), p-value

cox = coxph(Surv(futime, status=='T')~.-proc_type1-CAN_HGT_CM-PERS_ID+pspline(CAN_HGT_CM), data =cand1, weights = ipw_n/ipw_d)

# combine HR, 95% CI and pval
cox.out = round(data.frame(HR=exp(coef(cox)), exp(confint(cox))), 3) %>%
  rename(LCL=X2.5.., UCL=X97.5..) %>%
  mutate(Variable=rownames(.),
         Variable=ifelse(Variable=='CAN_PRELIM_XMATCH_REQUESTY', 'CAN_PRELIM_XMATCH_REQUEST', Variable)) %>%
  right_join(data.frame(p=summary(cox)$coefficients[, 6]) %>% 
               mutate(Variable=rownames(.),
                      p=format.pval(p, digits=2, eps=0.001)), 'Variable') %>%
  select(Variable, HR, LCL, UCL, p)

# Change column names for categorical columns into "varnames: level"
for(x in c('CAN_GENDER', 'race', 'CAN_CARDIAC_SURG', 'ABO', 'proc_type', 'payment', 'COPD_IPF')){
  for(row in cox.out$Variable){
    if(grepl(paste0('^', x), row)){
     cox.out[cox.out$Variable==row, 'Variable']=paste0(x, ': ', gsub(x, '', row))
    }
  }
}

# output look like:
                    Variable    HR   LCL   UCL      p
1         CAN_AGE_AT_LISTING 1.020 1.017 1.023 <0.001
2              CAN_GENDER: F 0.816 0.770 0.864 <0.001
3                race: Black 1.024 0.956 1.098  0.495
4             race: Hispanic 0.978 0.887 1.078  0.659
5                race: Other 0.847 0.729 0.984  0.030
6  CAN_PRELIM_XMATCH_REQUEST 0.621 0.542 0.713 <0.001
7                    CAN_BMI 0.963 0.959 0.967 <0.001
8            ventilator_ecmo 1.357 1.065 1.729  0.014
9        CAN_CARDIAC_SURG: U 0.967 0.801 1.168  0.728
10       CAN_CARDIAC_SURG: Y 0.840 0.761 0.926 <0.001
11          payment: Private 1.043 1.007 1.081  0.020
12       payment: Self/Other 1.353 1.068 1.713  0.012
13         proc_type: Either 0.956 0.917 0.997  0.036
14         proc_type: Single 1.166 1.115 1.220 <0.001
15            CAN_AT_REST_O2 1.098 1.090 1.106 <0.001
16             COPD_IPF: IPF 1.838 1.766 1.914 <0.001
17                    ABO: A 1.101 1.061 1.143 <0.001
18                   ABO: AB 1.660 1.515 1.820 <0.001
19                    ABO: B 1.253 1.181 1.328 <0.001
20                  art_mean 1.008 1.005 1.010 <0.001
21 pspline(CAN_HGT_CM), line    NA    NA    NA <0.001
22 pspline(CAN_HGT_CM), nonl    NA    NA    NA <0.001
