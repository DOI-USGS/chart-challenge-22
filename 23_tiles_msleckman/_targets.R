library(targets)
library(dplyr, quietly = T)
library(RColorBrewer, quietly = T)

options(tidyverse.quiet = TRUE)

tar_option_set(packages = c("tidyverse", "lubridate",
                            "dataRetrieval","sf",
                            "purrr", "sbtools", "terra",
                            'nhdplusTools','raster',
                            'FedData', 'RColorBrewer','lattice',
                            'rasterVis', 'magick', 'stringr',
                            'FedData', 'cowplot', 'showtext')
               )

source("1_fetch.R")
source("2_process.R")
source("3_visualize.R")

dir.create("1_fetch/out/", showWarnings = FALSE)
dir.create('1_fetch/out/nlcd/', showWarnings = FALSE)
dir.create("2_process/out/", showWarnings = FALSE)
dir.create('2_process/out/reclassified/', showWarnings = FALSE)
dir.create("3_visualize/out/", showWarnings = FALSE)
dir.create("3_visualize/out/barplot/", showWarnings = FALSE)
dir.create("3_visualize/out/levelplot/", showWarnings = FALSE)

all_years <- c('1900','1910','1920','1930','1940','1950',
               '1960','1970','1980','1990','2000','2001','2011','2019'
               )

nlcd_years <- list('2001',
                   # '2004',
                   # '2006',
                   '2011',
                   # '2013',
                   # '2016',
                   '2019')

# defining reclassify_df for 
reclassify_df_FOR <- read.delim('1_fetch/in/legend_color_map_FORESCE.csv', sep = ',') %>% filter(Reclassify_match != 'NA')

reclassify_df_nlcd <- read.delim('1_fetch/in/legend_color_map_NLCD.csv', sep = ',') %>% filter(., Reclassify_match != 'NA')
# defining legend dataframe
## [1]
legend_df <- reclassify_df_FOR %>% 
  arrange(Reclassify_match) %>% 
  dplyr::select(-c(FORESCE_value, FORESCE_description, color_name)) %>%
  distinct()

# legend_df_nlcd <- reclassify_df_nlcd %>% 
#   arrange(Reclassify_match) %>%
#   dplyr::select(-c(NLCD_value, NLCD_description, color_name)) %>%
#   distinct(Reclassify_match, Reclassify_description)
  
# ## [2]
# legend_df <- legend_df %>% 
#   mutate(color = brewer.pal(nrow(legend_df), "Set3")) 

# Returning the complete list of targets
c(p1_targets_list, p2_targets_list, p3_targets_list)



