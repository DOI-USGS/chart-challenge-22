library(targets)
library(tarchetypes)

source("src/prep_functions.R")
source("src/plot_functions.R")

options(tidyverse.quiet = TRUE,
        clustermq.scheduler = "multiprocess")
tar_option_set(packages = c("tidyverse", "lubridate", "scico", "paletteer","BAMMtools","scales", "ggforce"))

list(
  # Streamflow drought events calculated using Julian day 30-day moving window method 
  # for 1980-2020 for gages in Colorado River Basin region. 
  # Data file from regional drought early warning project 
  # Data > Data from National Project > Streamflow > Drought Summaries
  tar_target(events_crb_jd_1980_2020,
             read_csv("data/weibull_jd_30d_wndw_Drought_Properties.csv")), 
  
  # Preliminary version of file which includes 2021 data
  tar_target(events_crb_jd_1980_2021,
             read_csv("data/weibull_jd_30d_wndw_Drought_Properties_2021.csv")), 
  
  # Read in gage metadata for sites that are part of RDEWS project. Data file from regional drought early warning project 
  # Data > Data from National Project > Streamflow 
  tar_target(rdews_gages,
             {read_csv("data/all_gages_metadata.csv") %>% rename(StaID = site)}),
  
  # create event swarms for each time period
  tar_target(event_swarm_1980_1990_t5,
             create_event_swarm(event_data = events_crb_jd_1980_2020, 
                                metadata = rdews_gages,
                                start_period = as.Date("1980-01-01"),
                                end_period = as.Date("1989-12-31"),
                                target_threshold = 5)),
  tar_target(event_swarm_1990_2000_t5,
             create_event_swarm(event_data = events_crb_jd_1980_2020, 
                                metadata = rdews_gages,
                                start_period = as.Date("1990-01-01"),
                                end_period = as.Date("1999-12-31"),
                                target_threshold = 5)),
  tar_target(event_swarm_2000_2010_t5,
             create_event_swarm(event_data = events_crb_jd_1980_2020, 
                                metadata = rdews_gages,
                                start_period = as.Date("2000-01-01"),
                                end_period = as.Date("2009-12-31"),
                                target_threshold = 5)),
  tar_target(event_swarm_2010_2020_t5,
             create_event_swarm(event_data = events_crb_jd_1980_2020, 
                                metadata = rdews_gages,
                                start_period = as.Date("2010-01-01"),
                                end_period = as.Date("2019-12-31"),
                                target_threshold = 5)),
  tar_target(event_swarm_2021_t5,
             create_event_swarm(event_data = events_crb_jd_1980_2021, 
                                metadata = rdews_gages,
                                start_period = as.Date("2020-01-01"),
                                end_period = as.Date("2021-12-31"),
                                target_threshold = 5)),
  # count number of events per decade
  tar_target(event_counts_per_decade,
             count_events(event_data  = events_crb_jd_1980_2020, 
                          metadata = rdews_gages,
                          target_threshold = 5
                          )),
  # find the longest drought event per decade
  tar_target(longest_drought_per_decade,
             longest_events(event_data = events_crb_jd_1980_2020,
                            metadata = rdews_gages,
                            target_threshold = 5
                            )),
  
  # create plots
  tar_target(upper_crb_jd_5_1980_2020,
             multi_panel_swarm_plot(event_swarm_1980_1990_t5,
                                    event_swarm_1990_2000_t5,
                                    event_swarm_2000_2010_t5,
                                    event_swarm_2010_2020_t5
                                    )),
  tar_target(upper_crb_jd_5_1980_2020_png,
             ggsave('out/uppercol_jd_5_1980-2020.png', upper_crb_jd_5_1980_2020),
             format = "file" ),

  tar_target(upper_crb_jd_5_2021,
             event_swarm_plot(swarm_data = event_swarm_2021_t5)),
  tar_target(upper_crb_jd_5_2021_png,
             ggsave('out/uppercol_jd_5_2021.png', upper_crb_jd_5_2021),
             format = "file" )

)