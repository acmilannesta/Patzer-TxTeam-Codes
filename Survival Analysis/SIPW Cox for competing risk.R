# IPW denominator 
# logistic regression on competing event with same covaraiates in the Cox model
ipw_d = glm(status=='D/R'~.-futime-proc_type1, family = binomial(), data =cand1) %>%
  predict(., type = 'response')

# IPW numerator
# logistic regression on competing event with intercept only
ipw_n = glm(status=='D/R'~1, family = binomial(), data =cand1) %>%
  predict(., type = 'response')

# SIPW (stablized inverse probability weighting) = ipw_n / ipw_d
cox = coxph(Surv(futime, status=='T')~.-proc_type1-CAN_HGT_CM-PERS_ID+pspline(CAN_HGT_CM), data =cand1, weights = ipw_n/ipw_d)
