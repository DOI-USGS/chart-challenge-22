library(targets)
library(dplyr, quietly = T)
library(RColorBrewer, quietly = T)

options(tidyverse.quiet = TRUE)

tar_option_set(packages = c("tidyverse", "lubridate",
                            "dataRetrieval","sf",
                            "sbtools", "terra",
                            'nhdplusTools','raster',
                            'FedData', 
                            'magick', 
                            'FedData', 'cowplot', 'showtext')
               )

source("1_fetch.R")
source("2_process.R")
source("3_visualize.R")

## Creating sub-folders, especially for placing outputs imgs or tifs in an organized way
dir.create("1_fetch/out/", showWarnings = FALSE)
dir.create('1_fetch/out/nlcd/', showWarnings = FALSE)
dir.create("2_process/out/", showWarnings = FALSE)
dir.create('2_process/out/reclassified/', showWarnings = FALSE)
dir.create("3_visualize/out/", showWarnings = FALSE)
dir.create("3_visualize/out/map/", showWarnings = FALSE)
dir.create("3_visualize/out/frames/", showWarnings = FALSE)
dir.create("3_visualize/out/gifs/", showWarnings = FALSE)

# defining the zreclassify dfs for nlcd and FORESCE since the land cover classification is different  
reclassify_df_FOR <- read.delim('1_fetch/in/legend_color_map_FORESCE.csv', sep = ',') %>% filter(Reclassify_match != 'NA')
reclassify_df_nlcd <- read.delim('1_fetch/in/legend_color_map_NLCD.csv', sep = ',') %>% filter(., Reclassify_match != 'NA')

# defining legend df . Does not matter if derived from reclassify_df_FOR or reclassify_df_nlcd. reclassify_df_FOR chosen here. 
legend_df <- reclassify_df_FOR %>% 
  arrange(Reclassify_match) %>% 
  dplyr::select(-c(FORESCE_value, FORESCE_description, color_name)) %>%
  distinct() %>%
  mutate(lc_label = ifelse(stringr::word(Reclassify_description, 1, 1) == 'Developed', 
                           gsub('Areas ', '', Reclassify_description),
                           Reclassify_description))

# Returning the complete list of targets
c(p1_targets_list, p2_targets_list, p3_targets_list)



