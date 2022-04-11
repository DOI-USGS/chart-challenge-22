library(tibble)
library(dplyr)
library(tidyr)
library(lubridate)
library(data.table)
library(readr)
library(RColorBrewer)
library(stringr)
library(ggplot2)
library(circular)
library(cowplot)
library("dataRetrieval")

cfs_to_mm <- 28320000 * 86400 / (1000000 * 1000000)
my.palette <- brewer.pal(n=10, name = 'RdYlBu')

# Read in site list for UCRB
load("data_in/site_list_CRB.RData")

# Pull site information for site_list
loc_df <- readNWISsite(site_list)  %>%
  rename(site = site_no, latitude = dec_lat_va, longitude = dec_long_va) %>%
  mutate(DRAIN_SQKM = drain_area_va*2.5899) %>% # convert to km2
  mutate(HUC02 = substr(huc_cd, 1, 2)) %>%
  select(site, HUC02, DRAIN_SQKM)

# NWIS parameters
pCd <- "00060" #Discharge, cubic feet per second, see readNWISdv help file for more options
start_date <- as.Date("1980-04-01")
end_date <- as.Date("2021-12-31")

# Download NWIS Data if set to TRUE
download_new_data <- TRUE
if (download_new_data == TRUE){
  for (i in 1:length(site_list)){
    #NWIS data pull
    station <- site_list[i]
    cat(station, i, "of", length(site_list), "\n")
  
    df <- readNWISdv(station,pCd,start_date,end_date) %>%
      renameNWISColumns() %>%
      as_tibble()
  
    write_csv(df, paste0("data_in/NWIS_data/CRB/", station, ".csv"))
  }
}
  
# Read in all individual percentile files. 
df_list <- c()
for (i in 1:length(site_list)){
  tryCatch({
    print(i)
    
    df_temp <- read.csv(paste0("data_in/NWIS_data/CRB/", site_list[[i]], ".csv")) %>%
      as_tibble()
    
    df_list[[i]] <- df_temp
  }, error=function(e){cat("Site", i, "ERROR ", conditionMessage(e), "\n")})
}

# Take data from all sites and bind them together. 
# Subset to desired columns and modify site names to be 8 char
# Add metadata and subset to just upper CRB, HUC 14
# Add date information
# Remove extra day from leap years. 
# Subset to only approved data. 
# Summarize data from all years to a comprehensive value for each julian day. 
# Add information for plotting months. Note that months are all averaged length. 
df_ucrb <- bind_rows(df_list) %>%
  as_tibble() %>%
  select(c(site_no, Date, Flow, Flow_cd)) %>%
  mutate(site_no = str_pad(site_no, width=8, side="left", pad = "0"),
         site = site_no,
         value = Flow) %>%
  left_join(loc_df, by = 'site') %>%
  filter(HUC02 == '14') %>%
  mutate(Date = as_date(Date)) %>%
  mutate(jd = yday(Date),
         month = month(Date),
         year = year(Date)) %>%
  filter(jd <= 365) %>%
  filter(Date <= as_date("2020-03-31")) %>%
  filter(Flow_cd %in% c('A' ,'A:e' ,'A e','A [0]' ,'A R' ,'A [4]', "A <")) %>%
  group_by(jd) %>%
  summarize(mean_ann_flow = sum(value, na.rm = TRUE)/70,
            mean_mm_flow = mean((!!cfs_to_mm *(value/DRAIN_SQKM)), na.rm= TRUE),
            median_mm_flow = median((!!cfs_to_mm *(value/DRAIN_SQKM)), na.rm= TRUE),
            mean_site_flow = mean(value, na.rm = TRUE),
            month = first(month)) %>%
  mutate(month_ab = month.abb[month],
         month_start = month * 30.4 - 30,
         month_median = month * 30.4 - 15,
         month_end = month * 30.4)

saveRDS(df_ucrb, 'data_in/annual_flow_crb.rds')
# Driest day Feb 4th jd 35 0.1572965
# Wettest day June 8 jd 159 2.6224430

## Plot Upper CO
# This type of chart might be called a radial area plot. 
p_1 <- ggplot(data = df_ucrb, aes(x=jd, y = mean_mm_flow)) + 
  geom_bar(aes(fill = mean_mm_flow), 
           stat="identity", 
           width = 1.4, 
           position = "stack") +
  geom_line() +
  coord_polar(start = 0, direction = 1) +
  ylim(-1, 3) + 
  xlim(0, 376) +
  # annotate("text", x = rep(372,4), y = c(150000,1000000, 2000000, 3000000), label = c("0-", "1m-", "2m-", "3m-") , color="grey", size=3 , angle=0, fontface="bold") +
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    plot.margin = unit(rep(-1,4), "cm"), # This remove unnecessary margin around plot
    legend.position = c(.35,.65)
  ) +
  scale_fill_gradientn(colours = my.palette,
                       limits = c(0, 1),
                       oob = scales::squish) +
  labs(fill = "Upper Site Average CFS") + 
  geom_segment(data=df_ucrb, aes(x = month_start + 2, y = -.1, xend = month_end - 2, yend = -.1), colour = "black", alpha=0.8, size=1)  +
  geom_text(data=df_ucrb, aes(x = month_median, y = -.3, label=month_ab)) +
  geom_rect(xmin = 34, ymin = 0, xmax = 36, ymax = 0.1586426, color = "white", fill = NA, size = 0.5) +
  geom_rect(xmin = 158, ymin = 0, xmax = 160, ymax = 2.6636679, color = "white", fill = NA, size = 0.5) +
  geom_segment(aes(x = 10, y = 0.6, xend = 33, yend = 0.18), arrow = arrow(length = unit(0.5, "cm"))) +
  geom_segment(aes(x = 145, y = 2.5, xend = 155, yend = 2.6), arrow = arrow(length = unit(0.5, "cm"))) +
  annotate(geom="text", x=130, y=2.5, label="June 8\n Wettest Day \n of the Year", color="black") +
  annotate(geom="text", x=370, y=0.9, label="February 4\n Driest Day \n of the Year", color="black")
p_1

# Take data from all sites and bind them together. 
# Subset to desired columns and modify site names to be 8 char
# Add metadata and subset to just lower CRB, HUC 14
# Add date information
# Remove extra day from leap years. 
# Subset to only approved data. 
# Summarize data from all years to a comprehensive value for each julian day. 
# Add information for plotting months. Note that months are all averaged length. 
df_lcrb <- bind_rows(df_list) %>%
  as_tibble() %>%
  select(c(site_no, Date, Flow, Flow_cd)) %>%
  mutate(site_no = str_pad(site_no, width=8, side="left", pad = "0"),
         site = site_no,
         value = Flow) %>%
  left_join(loc_df, by = 'site') %>% 
  filter(HUC02 == '15') %>% 
  mutate(Date = as_date(Date)) %>%
  mutate(jd = yday(Date),
         month = month(Date),
         year = year(Date)) %>%
  filter(jd <= 365) %>%
  filter(Date <= as_date("2020-03-31")) %>%
  filter(Flow_cd %in% c('A' ,'A:e' ,'A e','A [0]' ,'A R' ,'A [4]', "A <")) %>%
  group_by(jd) %>%
  summarize(mean_ann_flow = sum(value, na.rm = TRUE)/70,
            mean_mm_flow = mean((!!cfs_to_mm *(value/DRAIN_SQKM)), na.rm= TRUE),
            median_mm_flow = median((!!cfs_to_mm *(value/DRAIN_SQKM)), na.rm= TRUE),
            mean_site_flow = mean(value, na.rm = TRUE),
            month = first(month)) %>%
  mutate(month_ab = month.abb[month],
         month_start = month * 30.4 - 30,
         month_median = month * 30.4 - 15,
         month_end = month * 30.4)

# Driest Oct 15th jd 288 0.04657738
# Wettest Feb 15th jd 46 0.46962842

## Plot Lower CO
p_2 <- ggplot(data = df_lcrb, aes(x=jd, y = mean_mm_flow)) + 
  geom_bar(aes(fill = mean_mm_flow), stat="identity", width = 1.4) +
  geom_line() +
  coord_polar(start = 0, direction = 1) +
  ylim(-1, 3) + 
  xlim(0, 376) + 
  theme_minimal() +
  theme(
    axis.text = element_blank(),
    axis.title = element_blank(),
    panel.grid = element_blank(),
    plot.margin = unit(rep(-1,4), "cm"), # This remove unnecessary margin around plot
    legend.position = c(.5,.25),
    plot.title = element_text(face = "bold")
  ) +
  scale_fill_gradientn(colours = my.palette,
                       limits = c(0, 1),
                       oob = scales::squish) +
  labs(fill = "Flow rate by basin area\nmm/day") + 
  geom_segment(data=df_lcrb, 
               aes(x = month_start + 2, y = -.1, xend = month_end - 2, yend = -.1), 
               colour = "black", alpha=0.8, size=1)  +
  geom_text(data=df_lcrb, 
            aes(x = month_median, y = -.3, label=month_ab)) + 
  # geom_rect(xmin = 45, ymin = 0, xmax = 47, ymax = 0.45302850, color = "grey", fill = NA, size = 1) +
  geom_rect(xmin = 7, ymin = 0, xmax = 9, ymax = 0.4696284, color = "white", fill = NA, size = 0.5) +
  geom_rect(xmin = 287, ymin = 0, xmax = 289, ymax = 0.04834458, color = "white", fill = NA, size = 0.5) +
  # geom_segment(aes(x = 10, y = 0.6, xend = 35, yend = 0.18), arrow = arrow(length = unit(0.5, "cm"))) +
  geom_segment(aes(x = 270, y = .6, xend = 285, yend = .1), arrow = arrow(length = unit(0.5, "cm"))) +
  # annotate(geom="text", x=46, y=1.1, label="Feb 15\n Wettest Day \n of the Year", color="black") +
  annotate(geom="text", x=8, y=1.1, label="Jan 8\n Wettest Day \n of the Year", color="black") +
  annotate(geom="text", x=255, y=.75, label="Oct 15\n Driest Day \n of the Year", color="black") +
  guides(fill = guide_colorbar(
    direction = "horizontal",
    barwidth = 12,
    title.position = "top"
  ))
p_2

fig_text <- "Average flow rate normalized by basin area (mm per day) for USGS NWIS gages from 1981 - 2020 in the upper and 
lower Colorado River Basins. Flow is in mm per day across the entire basin area contributing 
to each gage."

ggdraw() +
  draw_plot(p_1 + theme(legend.position = "none"), x= -.45, y = 0, width = 1.4, height = 1 ) +
  draw_plot(p_2 + theme(legend.title = element_text(size=12, face= "bold")), x= .0, y = 0, width = 1.4, height = 1 ) +
  draw_label("A Tale of Two Basins", x = 0.5, y = 0.875, fontface = "bold", size = 20, hjust = 0.5) +
  draw_text(fig_text, x = 0.5, y = 0.1, size = 12) +
  draw_text("Upper Colorado", x = 0.24, y = 0.8, size = 14, fontface = "bold") +
  draw_text("Lower Colorado", x = 0.7, y = 0.8, size = 14, fontface = "bold")
ggsave("viz/Wettest_Day_of_the_Year_CRB.png", width = 10, height = 8)
