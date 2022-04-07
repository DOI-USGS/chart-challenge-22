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


cfs_to_mm <- 28320000 * 86400 / (1000000 * 1000000)

# Read in metadata for plotting. 
# Metadata are derived from Gages II metadata here: https://water.usgs.gov/GIS/metadata/usgswrd/XML/gagesII_Sept2011.xml
# and from site information from each site available on NWIS. 
station_metadata <- read.csv("11_circular_csimeone/data_in/NWIS_data/CRB/colorado_metadata_all.csv",header=TRUE,stringsAsFactors = FALSE)
station_metadata$site <- str_pad(station_metadata$site, width=8, side="left", pad = "0") 
loc_df <- station_metadata %>%
  as_tibble() %>%
  rename(latitude = lat, longitude = long) %>%
  filter(HUC02 %in% c(14, 15)) %>%
  dplyr::select(c(site, HUC02, DRAIN_SQKM))

load("11_circular_csimeone/data_in/site_list_CRB.RData")


pCd <- "00060" #Discharge, cubic feet per second, see readNWISdv help file for more options
start_date <- as.Date("1950-04-01")
end_date <- as.Date("2021-12-31")

# for (i in 1:length(site_list)){
#   #NWIS data pull
#   station <- site_list[i]
#   cat(station, i, "of", length(site_list), "\n")
# 
#   df <- readNWISdv(station,pCd,start_date,end_date) %>%
#     renameNWISColumns() %>%
#     as_tibble()
# 
#   write_csv(df, paste0("../NWIS_Download/CRB/", station, ".csv"))
# }

# Read in all individual percentile files. 
df_list <- c()
for (i in 1:length(site_list)){
  tryCatch({
    print(i)
    
    df_temp <- read.csv(paste0("11_circular_csimeone/data_in/NWIS_data/CRB/", site_list[[i]], ".csv")) %>%
      as_tibble()
    # df_temp$site <- site_list[[i]]
    
    df_list[[i]] <- df_temp
  }, error=function(e){cat("Site", i, "ERROR ", conditionMessage(e), "\n")})
}

df_ucrb <- bind_rows(df_list) %>%
  as_tibble() %>%
  select(c(site_no, Date, Flow, Flow_cd)) %>%
  mutate(site_no = str_pad(site_no, width=8, side="left", pad = "0"),
         site = site_no,
         value = Flow) %>%
  left_join(loc_df, by = 'site') %>%
  filter(HUC02 %in% c(14)) %>%
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
            mean_site_flow = mean(value, na.rm = TRUE),
            month = first(month)) %>%
  mutate(month_ab = month.abb[month],
         month_start = month * 30.4 - 30,
         month_median = month * 30.4 - 15,
         month_end = month * 30.4)

  # Driest day Feb 4th jd 35 0.1572965
  # Wettest day June 8 jd 159 2.6224430

# This type of chart might be called a radial area plot. 
my.palette <- brewer.pal(n=10, name = 'RdYlBu')

p_1 <- ggplot(data = df_ucrb, aes(x=jd, y = mean_mm_flow)) + 
  # geom_area(fill = 'blue', alpha = 0.5) +
  geom_bar(aes(fill = mean_mm_flow), stat="identity", width = 1.4) +
  geom_line() +
  coord_polar(start = 0, direction = 1) +
  ylim(-1, 3) + 
  # facet_wrap(~HUC02) +
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
  geom_segment(x = 35, y = 0, xend = 35, yend = 0.1572965, color = "grey", size = 2) +
  geom_segment(x = 159, y = 0, xend = 159, yend = 2.6224430, color = "grey", size = 2) +
  geom_segment(aes(x = 10, y = 0.6, xend = 33, yend = 0.18), arrow = arrow(length = unit(0.5, "cm"))) +
  geom_segment(aes(x = 145, y = 2.5, xend = 155, yend = 2.6), arrow = arrow(length = unit(0.5, "cm"))) +
  annotate(geom="text", x=130, y=2.5, label="June 8\n Wettest Day \n of the Year", color="black") +
  annotate(geom="text", x=370, y=0.9, label="February 4\n Driest Day \n of the Year", color="black")

df_lcrb <- bind_rows(df_list) %>%
  as_tibble() %>%
  select(c(site_no, Date, Flow, Flow_cd)) %>%
  mutate(site_no = str_pad(site_no, width=8, side="left", pad = "0"),
         site = site_no,
         value = Flow) %>%
  left_join(loc_df, by = 'site') %>%
  filter(HUC02 %in% c(15)) %>%
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
            mean_site_flow = mean(value, na.rm = TRUE),
            month = first(month)) %>%
  mutate(month_ab = month.abb[month],
         month_start = month * 30.4 - 30,
         month_median = month * 30.4 - 15,
         month_end = month * 30.4)

# Driest Oct 15th jd 288 0.04657738
# Wettest Feb 15th jd 46 0.46962842




p_2 <- ggplot(data = df_lcrb, aes(x=jd, y = mean_mm_flow)) + 
  # geom_area(fill = 'blue', alpha = 0.5) +
  geom_bar(aes(fill = mean_mm_flow), stat="identity", width = 1.4) +
  geom_line() +
  coord_polar(start = 0, direction = 1) +
  ylim(-1, 3) + 
  # facet_wrap(~HUC02) +
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
  labs(fill = "mm/d flow") + 
  geom_segment(data=df_lcrb, aes(x = month_start + 2, y = -.1, xend = month_end - 2, yend = -.1), colour = "black", alpha=0.8, size=1)  +
  geom_text(data=df_lcrb, aes(x = month_median, y = -.3, label=month_ab)) + 
  geom_segment(x = 46, y = 0, xend = 46, yend = 0.45302850, color = "grey", size = 2) +
  geom_segment(x = 288, y = 0, xend = 288, yend = 0.04657738, color = "grey", size = 2) +
  # geom_segment(aes(x = 10, y = 0.6, xend = 35, yend = 0.18), arrow = arrow(length = unit(0.5, "cm"))) +
  geom_segment(aes(x = 270, y = .6, xend = 285, yend = .1), arrow = arrow(length = unit(0.5, "cm"))) +
  annotate(geom="text", x=46, y=1.1, label="Feb 15\n Wettest Day \n of the Year", color="black") +
  annotate(geom="text", x=255, y=.75, label="Oct 15\n Driest Day \n of the Year", color="black")

fig_text <- "Average flow rate normalized by basin area for USGS NWIS gages in the upper (left) and lower (right) 
Colorado River Basins. The flow is in mm per day across the entire basin area contributing to each gage."

ggdraw() +
  draw_plot(p_1 + theme(legend.position = "none"), x= -.45, y = 0, width = 1.4, height = 1 ) +
  draw_plot(p_2 + theme(legend.title = element_text(size=12)), x= .0, y = 0, width = 1.4, height = 1 ) +
  draw_label("A Tale of Two Basins", x = 0.5, y = 0.85) +
  draw_text(fig_text, x = 0.5, y = 0.1, size = 12)
ggsave("11_circular_csimeone/viz/Wettest_Day_of_the_Year_CRB.png", width = 8, height = 8)
