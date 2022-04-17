library(targets)
library(tarchetypes)

source("src/prep_functions.R")
source("src/plot_functions.R")

options(tidyverse.quiet = TRUE,
        clustermq.scheduler = "multiprocess")
tar_option_set(packages = c("tidyverse", "lubridate", "scico", "paletteer",
                            "BAMMtools","scales", "ggforce", "showtext", "cowplot"))

list(
  # Streamflow drought events calculated using Julian day 30-day moving window method 
  # for 1980-2020 for gages in Colorado River Basin region. 
  # Data file from regional drought early warning project 
  # Data > Data from National Project > Streamflow > Drought Summaries
  tar_target(events_crb_jd_1980_2020,
             read_csv("data/weibull_jd_30d_wndw_Drought_Properties.csv") %>%
               transform(StaID = as.character(StaID)) %>%
               mutate(across(c(start, end, previous_end), ~as.Date(.x, '%m/%d/%y')))
             ), 

  # Preliminary version of file which includes 2021 data
  tar_target(events_crb_jd_1980_2021,
             read_csv("data/weibull_jd_30d_wndw_Drought_Properties_2021.csv") %>%
               transform(StaID = as.character(StaID))%>%
               mutate(across(c(start, end, previous_end), ~as.Date(.x, '%m/%d/%y')))
             ), 
  # Combine data long format
  tar_target(
    crb_events,
    bind_rows(events_crb_jd_1980_2020, events_crb_jd_1980_2021) %>%
      distinct() %>%
      transform(StaID = as.character(StaID))%>%
      mutate(across(c(start, end, previous_end), ~as.Date(.x, '%m/%d/%y')))
  ),
  
  # Read in gage metadata for sites that are part of RDEWS project. Data file from regional drought early warning project 
  # Data > Data from National Project > Streamflow 
  tar_target(rdews_gages,
             {read_csv("data/all_gages_metadata.csv", col_types = 'ccncnncclnnnnnnnnnnnnncccnc') %>% 
                 transform(StaID = as.character(site))
               }
             ),
  # create event swarms for each time period
  tar_target(event_swarm_all,
             create_event_swarm(event_data = crb_events, 
                                metadata = rdews_gages,
                                start_period = as.Date("1980-01-01"),
                                end_period = as.Date("2021-12-31"),
                                target_threshold = 5)),
  # count number of events per decade
  tar_target(event_counts_per_decade,
             count_events(event_data  = crb_events, 
                          metadata = rdews_gages,
                          target_threshold = 5
                          )),
  # find the longest drought event per decade
  tar_target(longest_drought_per_decade,
             longest_events(event_data = crb_events,
                            metadata = rdews_gages,
                            target_threshold = 5
                            )),
  
  # Create plots
  # "Strip swarm" for just 2021
  tar_target(upper_crb_jd_5_2021,
             event_swarm_plot(swarm_data = event_swarm_2021_t5)),
  # "Strip swarm" using all data, horizontal layout
  tar_target(upper_crb_jd_5_1980_2021,
             horiz_swarm_plot(swarm_data = event_swarm_all)),
  
  # Export plots
  tar_target(upper_crb_jd_5_1980_2020_png,
             ggsave('out/uppercol_jd_5_1980-2020.png', upper_crb_jd_5_1980_2020,
                    width = 10, height = 10, dpi = 300),
             format = "file" ),
  tar_target(upper_crb_jd_5_2021_png,
             ggsave('out/uppercol_jd_5_2021.png', upper_crb_jd_5_2021,
                    width = 8, height = 5, dpi = 300),
             format = "file" ),
  tar_target(upper_crb_jd_5_1980_2021_png,
             ggsave('out/uppercol_jd_5_1980-2021.png', upper_crb_jd_5_1980_2021,
                    width = 14, height = 10, dpi = 300),
             format = "file" )

)