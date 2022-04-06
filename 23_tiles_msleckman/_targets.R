library(targets)

options(tidyverse.quiet = TRUE)

tar_option_set(packages = c("tidyverse", 'dplyr', "lubridate",
                            "rmarkdown","dataRetrieval",
                            "knitr","leaflet","sf",
                            "purrr", "sbtools", "terra",
                            'nhdplusTools','raster','sp', 'FedData'))

source("1_fetch.R")
source("2_process.R")
source("3_visualize.R")

dir.create("1_fetch/out/", showWarnings = FALSE)
dir.create("2_process/out/", showWarnings = FALSE)
dir.create("3_visualize/out/", showWarnings = FALSE)
dir.create("3_visualize/log/", showWarnings = FALSE)
dir.create("3_visualize/out/daily_timeseries_png/",showWarnings = FALSE)
dir.create("3_visualize/out/hourly_timeseries_png/",showWarnings = FALSE)
dir.create("3_visualize/out/nhdv2_attr_png/",showWarnings = FALSE)

legend_df_path <- 'legend_color_map.csv'

reclassify_df <- read.delim(legend_df_path, sep = ',')
#color_match_for_join <- reclassify_df %>% dplyr::select(color) %>% head(., length(unique(reclassify_df$Reclassify_match)))

legend_df <- reclassify_df %>% arrange(Reclassify_match) %>% 
  dplyr::select(-c(FORESCE_value, FORESCE_description, color)) %>%
  distinct(Reclassify_match, Reclassify_description) %>%
  mutate(color = reclassify_df %>% dplyr::select(color) %>%
           head(., length(unique(reclassify_df$Reclassify_match))))

# Return the complete list of targets
c(p1_targets_list, p2_targets_list, p3_targets_list)


