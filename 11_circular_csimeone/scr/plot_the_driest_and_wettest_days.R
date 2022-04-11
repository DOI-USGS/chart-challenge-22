# Download NWIS Data For UCRB

library(dataRetrieval)
library(tidyverse)
library(lubridate)
library(RColorBrewer)
library(ggplot2)
library(circular)
library(cowplot)
library(grid)

# Read in site list
# Gages-2 sites with 70 years of data, near complete
download.file('https://labs.waterdata.usgs.gov/visualizations/data/site_list.RData', 'data_in/site_list.RData')
load("data_in/site_list.RData")

pCd <- "00060" #Discharge, cubic feet per second, see readNWISdv help file for more options
start_date <- as.Date("1950-04-01")
end_date <- as.Date("2021-12-31")

# Download NWIS Data if set to TRUE
# warning: this data download takes approximately 45 min
download_new_data <- TRUE
if (download_new_data == TRUE){
  for (i in 1:length(site_list)){
    #NWIS data pull
    station <- site_list[i]
    cat(station, i, "of", length(site_list), "\n")
    
    df <- readNWISdv(station,pCd,start_date,end_date) %>%
      renameNWISColumns() %>%
      as_tibble()
    
    write_csv(df, paste0("data_in/NWIS_data/", station, ".csv"))
  }
}

  
# Read in all individual percentile files. 
df_list <- c()
for (i in 1:length(site_list)){
  tryCatch({
    print(i)
    
    df_temp <- read.csv(paste0("data_in/NWIS_data/", site_list[[i]], ".csv")) %>%
      as_tibble()
    
    df_list[[i]] <- df_temp
  }, error=function(e){cat("Site", i, "ERROR ", conditionMessage(e), "\n")})
}

# Combine data and subset desired columns. 
# Add date information
# Remove extra day from leap years. 
# Subset to only approved data. 
df <- bind_rows(df_list) %>%
  as_tibble() %>%
  select(c(site_no, Date, Flow, Flow_cd)) %>%
  mutate(site_no = str_pad(site_no, width=8, side="left", pad = "0")) %>%
  mutate(Date = as_date(Date)) %>%
  mutate(jd = yday(Date),
         month = month(Date),
         year = year(Date)) %>%
  filter(jd <= 365) %>%
  filter(Date <= as_date("2020-03-31")) %>%
  filter(Flow_cd %in% c('A' ,'A:e' ,'A e','A [0]' ,'A R' ,'A [4]', "A <"))

saveRDS(df, 'data_in/annual_flow.rds')

# Summarize data from all years to a comprehensive value for each julian day. 
# Add information for plotting months. Note that months are all averaged length. 
df_jd <- df %>%
  group_by(jd) %>%
  summarize(mean_flow = sum(Flow, na.rm = TRUE)/70,
            month = first(month)) %>%
  mutate(month_ab = month.abb[month],
         month_start = month * 30.4 - 30,
         month_median = month * 30.4 - 15,
         month_end = month * 30.4)


# August 27th jd = 239 is the dryiest day of the year: 1152951
# April 6th jd = 96 is the wettest day of the year: 4277993

#Subset for each CY to fine wettest/driest days of period. 
df_jd_cy <- df %>%
  group_by(jd, year) %>%
  summarize(mean_flow = sum(Flow, na.rm = TRUE),
            month = first(month)) %>%
  mutate(month_ab = month.abb[month],
         month_start = month * 30.4 - 30,
         month_median = month * 30.4 - 15,
         month_end = month * 30.4)

# The wettest single day in the last 70 years was 1972 June 24th jd 175 at 10,975,834 ccfs
# The driest single day in the last 70 years was 1952 November 3rd  jd 307 at 530,098 cfs 
# Both of these align with major flood/drought events. 

my.palette <- brewer.pal(n=10, name = 'RdYlBu')

# This type of chart might be called a radial area plot. 
p_1 <- ggplot(data = df_jd, aes(x=jd, y = mean_flow)) + 
  geom_bar(aes(fill = mean_flow), stat="identity", width = 1.3) +
  geom_line() +
  geom_segment(aes(x = 140, y = 5500000, 
                   xend = 165, yend = 6800000), 
               arrow = arrow(length = unit(0.5, "cm"))) +
  geom_point(aes(x = 307, y = 5500000), 
             color = 'black', size = 3, shape = 21, fill = NA) +
  geom_point(aes(x = 129, y = 530098), 
            color = 'white', size = 3, shape = 21, fill = NA) +
  coord_polar(start = 0, direction = 1) +
  geom_segment(aes(x = 280, y = 2400000, 
                   xend = 305, yend = 540000), 
               arrow = arrow(length = unit(0.5, "cm"))) +
  ylim(-4000000, 7000000) + 
  xlim(0, 376) +
  annotate("text", x = rep(372,4), y = c(150000,1000000, 2000000, 3000000), 
           label = c("0-", "1m-", "2m-", "3m cfs-") , 
           color="grey", size=3 , angle=0, fontface="bold") +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    plot.margin = unit(rep(-1,4), "cm"), # This remove unnecessary margin around plot
    legend.position = c(.16,.6),
    legend.title = element_text(face = "bold")
  ) +
  scale_fill_gradientn(colours = my.palette,
                       breaks = c(2000000, 3000000, 4000000),
                       labels = c(2, 3, 4),
                       oob = scales::squish) +
  labs(fill = "Total Daily Flow Rate \nmillion CFS") +
  geom_rect(xmin = 95, ymin = 0, xmax = 97, ymax = 4277993, fill = NA, color = 'white', size = 0.5) +
  geom_rect(xmin = 238, ymin = 0, xmax = 240, ymax = 1152951, color = "white", size = 0.5, fill = NA) +
  annotate(geom="text", x=98, y=6200000, 
           label="April 6: Wettest Day\nof the Year, on average", color="black") +
  annotate(geom="text", x=242, y=3500000, 
           label="August 27: Driest Day\nof the Year, on average", color="black") +
  annotate(geom="text", x=275, y=3600000, 
           label="Nov 3, 1952:\n Driest Day \n 1951-2020", color="black") +
  annotate(geom="text", x=129, y=5700000, 
           label="June 24, 1972:\nWettest Day 1951-2020\nat 10,975,834 cfs \nit's off the chart!", color="black") +
  geom_segment(data=df_jd, 
               aes(x = month_start + 2, y = -100000, xend = month_end - 2, yend = -100000), 
               colour = "black", alpha=0.8, size=1)  +
  geom_text(data=df_jd, aes(x = month_median, y = -500000, label=month_ab))+
  guides(fill = guide_colorbar(
    direction = "horizontal",
    barwidth = 12,
    title.position = "top"
  ))

p_1

# compile plot elements with annotations
fig_text <- "The total flow rate in million cubic feet per second (cfs)\nfor 1,865 USGS NWIS gages with\nnear complete data 1951 - 2020."

# white box under text to block out arrow
rect <- rectGrob(
  x = 0.68,
  y = 0.13,
  width = unit(1, "in"),
  height = unit(0.2, "in"),
  hjust = 0, vjust = 1,
  gp = gpar(fill = "white", alpha = 1, col = 'white')
)

p_2 <- ggdraw() +
  draw_plot(p_1 , x=-0.11, y = -0.1, width = 1.2, height = 1.2 ) + 
  #draw_grob(rect) +
  draw_label("When are U.S. Rivers Wet or Dry?", x = 0.02, y = 0.9, fontface = "bold", size = 20, hjust = 0) +
  draw_text(fig_text, x = 0.02, y = 0.8, size = 12, hjust = 0)

p_2

ggsave(plot = p_2, "viz/Wettest_Day_of_the_Year.png", width = 10, height = 8)

