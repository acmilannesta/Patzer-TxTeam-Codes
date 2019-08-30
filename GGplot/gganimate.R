
library(ggplot2)
library(gganimate)
library(gapminder)
library(dplyr)


setwd('E:/RStudio/R project/gganimate')
data = read.csv('pollution.csv')

data_plot = subset(data, !is.na(pm2.5)) %>%
  select(year, month, pm2.5) %>%
  group_by(year, month) %>%
  summarise(m=mean(pm2.5), sd=sqrt(var(pm2.5)/length(pm2.5))) %>%
  mutate(time = as.Date(paste(year, '-', month, '-1', sep=''), '%Y-%m-%d')) %>%
  arrange(time)

#whole time period in one plot (gganimate1.gif)
p= ggplot(data_plot, aes(x = time, y=m))+
    geom_line(size=0.8)+
    geom_errorbar(aes(ymin = m-sd, ymax= m+sd, group=seq_along(time)), width=15,  size=0.8)+
    labs(x='Time', y='PM 2.5 level')+
    scale_x_date(breaks = '1 year', date_labels = '%Y')+
    ggtitle('Beijing PM 2.5 level in 2010-2014')+
    theme_minimal()+
    theme(axis.title=element_text(face='bold', size=16), 
        plot.title = element_text(face='bold', size=20, hjust = 0.5),
        strip.text = element_text(face='bold', size=16),
        axis.text = element_text(face='bold', size=12))

p

q= p+transition_reveal(time)
animate(q, width=2000, height=800, duration=15, renderer = gifski_renderer('gganimate1.gif'))

#whole time period in facet grid (gganimate2.gif)
p= ggplot(data_plot, aes(x = month, y=m))+
  geom_line(size=0.8)+
  geom_errorbar(aes(ymin = m-sd, ymax= m+sd, group=seq_along(month)), width=0.2, position = position_dodge(.9))+
  facet_wrap(~year, nrow=1)+
  labs(x='Month', y='PM 2.5 level')+
  scale_x_continuous(breaks = seq(2, 12, 2))+
  ggtitle('Beijing PM 2.5 level in 2010-2014')+
  theme_bw()+
  theme(axis.title=element_text(face='bold', size=16), 
        plot.title = element_text(face='bold', size=20, hjust = 0.5),
        strip.text = element_text(face='bold', size=16),
        axis.text = element_text(face='bold', size=12))

p

q= p+transition_reveal(month)
animate(q, width=2000, height=800, renderer = gifski_renderer('gganimate2.gif'))


