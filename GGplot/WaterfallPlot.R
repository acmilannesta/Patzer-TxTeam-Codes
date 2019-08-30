# Code for waterfallplot.jpg

library(ggplot2)

ggplot(plot.data, aes(x=id, y=value*100, fill=relevel(factor(group), 'ref_fac')))+
  geom_area(position = 'identity')+
  scale_fill_manual(values = c('#ED7D31', '#4CAEE3'), name='Status', labels=c('1-yr referred', '6-mo evaluated'))+
  scale_x_continuous(breaks=NULL)+
  scale_y_continuous(breaks=seq(0,100,10), limits = c(0,100))+
  labs(y='% of Dialysis Patients, 2012-2016', x='End-Stage Renal Disease Network 6 Dialysis Facilities (n=690)')+
  ggtitle('Variation in Early Steps in the Kidney Transplant Process \n among ESRD Network 6 Dialysis Facilities, 2012-2016')+
  geom_hline(yintercept=33.7, size=1, linetype = 'dotted')+
  geom_text(aes(label="Median % referred: \n 33.7%", x=50, y=40), color='Black', size=5)+
  theme_bw()+
  theme(plot.title = element_text(hjust = 0.5, size=20, face='bold'),
        axis.title.x = element_text(size=15, face='bold'),
        axis.title.y = element_text(size=15, face='bold'),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.text.y=element_text(size=15),
        legend.position = 'bottom', #c(0.1, 0.)
        legend.text = element_text(size=12, face='bold'), 
        legend.title = element_text(size=15, face='bold'))
        
