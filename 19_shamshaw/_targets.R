library(targets)
library(tarchetypes)

source("src/prep_functions.R")
source("src/plot_functions.R")

options(tidyverse.quiet = TRUE,
        clustermq.scheduler = "multiprocess")
tar_option_set(packages = c("tidyverse", "lubridate", "scico", "paletteer",
                            "BAMMtools","scales", "ggforce", "showtext", "cowplot"))

list(
  # Streamflow drought event start and end dates and durations 
  # for 1980-2020 for gages in Colorado River Basin region. 

  tar_target(event_data,
             read_csv("data/event_delineations.csv") %>%
               mutate(across(c(start, end), ~as.Date(.x, '%Y-%m-%d')))
             ), 

  # create event swarms for each time period
  tar_target(event_swarm_2021_t5,
             create_event_swarm(event_data = event_data, 
                                start_period = as.Date("2020-01-01"),
                                end_period = as.Date("2021-12-31"))),
  tar_target(event_swarm_all,
             create_event_swarm(event_data = event_data, 
                                start_period = as.Date("1980-01-01"),
                                end_period = as.Date("2021-12-31"))),

  # Create plots
  # "Strip swarm" for just 2021
  tar_target(upper_crb_jd_5_2021,
             event_swarm_plot(swarm_data = event_swarm_2021_t5)),
  # "Strip swarm" using all data, horizontal layout
  tar_target(upper_crb_jd_5_1980_2021,
             horiz_swarm_plot(swarm_data = event_swarm_all)),
  
  # Export plots
  tar_target(upper_crb_jd_5_2021_png,
             ggsave('out/uppercol_jd_5_2021.png', upper_crb_jd_5_2021,
                    width = 14, height = 10, dpi = 300),
             format = "file" ),
  tar_target(upper_crb_jd_5_1980_2021_png,
             ggsave('out/uppercol_jd_5_1980-2021.png', upper_crb_jd_5_1980_2021,
                    width = 14, height = 10, dpi = 300),
             format = "file" )

)