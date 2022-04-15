library(targets)
library(dplyr, quietly = T)
library(RColorBrewer, quietly = T)

options(tidyverse.quiet = TRUE)

tar_option_set(packages = c("tidyverse", "dplyr", "lubridate",
                            "rmarkdown","dataRetrieval",
                            "knitr","leaflet","sf",
                            "purrr", "sbtools", "terra",
                            'nhdplusTools','raster','sp',
                            'FedData', 'RColorBrewer','lattice',
                            'rgdal', 'rasterVis', 'magick', 'stringr',
                            'FedData')
               )

source("1_fetch.R")
source("2_process.R")
source("3_visualize.R")

dir.create("1_fetch/out/", showWarnings = FALSE)
dir.create('1_fetch/out/nlcd/', showWarnings = FALSE)
dir.create("2_process/out/", showWarnings = FALSE)
dir.create("3_visualize/out/", showWarnings = FALSE)

nlcd_years <- list('2001','2004','2006','2011','2013','2016',2019)

legend_df_path <- 'legend_color_map.csv'
# defining reclassify_df for 
reclassify_df <- read.delim(legend_df_path, sep = ',') %>% filter(Reclassify_match != 'NA')

# defining legend dataframe, [1] removing duplicates and then [2] reassigning colors (to streamline if time allows)
## [1]
legend_df <- reclassify_df %>%
  arrange(Reclassify_match) %>% 
  dplyr::select(-c(FORESCE_value, FORESCE_description, color)) %>%
  distinct(Reclassify_match, Reclassify_description)
## [2]
legend_df <- legend_df %>% 
  mutate(color = brewer.pal(nrow(legend_df), "Set3")) 

# Returning the complete list of targets
c(p1_targets_list, p2_targets_list, p3_targets_list)



