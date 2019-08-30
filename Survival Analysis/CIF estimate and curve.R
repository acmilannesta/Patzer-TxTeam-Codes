library(cmprsk)
library(dplyr)

# code status as numeric, default censor=0, event of interest=1, competing events = 2,...
cum.inc = cuminc(cand1$futime, cand1$status, group = cand1$proc_type)

# bind differnt groups
cif = rbind(data.frame(cum.inc$`Double 1`, proc_type='Double'), 
            data.frame(cum.inc$`Either 1`, proc_type='Either'),
            data.frame(cum.inc$`Single 1`, proc_type='Single'))

# median CIF time
cum.inc %>%
  filter(est<=0.5) %>%
  group_by(proc_type) %>%
  arrange(abs(est-0.5), time) %>%
  top_n(1, wt=time)

# cif curve (you could use the default plot function in cmprsk, but ggplot would provide more flexibility and control over
minor logistics)

ggplot(cif, aes(x=time, y=est)) +
  geom_line(aes(linetype=proc_type), size=1)+
  ggtitle('Cumulative incidence of 1-yr Lung Transplantation by procedure type')+
  scale_x_continuous(limits = c(0, 12), breaks=seq(0, 12, 2))+
  scale_y_continuous(limits=c(0,1), breaks = seq(0, 1, 0.2))+
  scale_linetype_manual(values=c("dotted", "dashed", "solid"))+
  labs(x='Time from Waitlisting in Months', 
       y='Cumulative incidence, %',
       linetype='Procedure\nType')+
  annotate('text',x=9, y=0.1, label='Median survival time in months\nDouble: 3.6\nEither: 3.8\nSingle: 2.4', hjust=0)+
  theme_bw()+
  theme(plot.title = element_text(hjust=.5))
