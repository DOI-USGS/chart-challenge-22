library(tidyverse)
library(nhdplusTools)
library(sf)

# Source helper functions
source("11_circular_lkoenig/src/orientation_helpers.R")

# Define huc8 basins
huc8_tbl <- tibble(huc8_id = c("05090202","07130009","02070001","17110014",
                               "03120002","10030205","17070204","10200103",
                               "04110002","15050203","08080101","02040101"),
                   huc8_name = c("Little Miami","Salt","South Branch Potomac",
                                 "Puyallup","Upper Ochlockonee","Teton",
                                 "Lower John Day", "Middle Platte-Prairie",
                                 "Cuyahoga","Lower San Pedro","Atchafalaya",
                                 "Upper Delaware"))

# Fetch NHDv2 flowlines for each huc8 basin
flines <- lapply(huc8_tbl$huc8_id, fetch_flowlines)

# Estimate channel orientation (i.e., azimuth) for each huc8 basin
# note that this step is taking a while to run, ~10 min?
flines_azimuth <- lapply(flines, function(x){
  az_df <- x %>%
    split(., 1:length(.$geometry)) %>%
    purrr::map_dfr(~mutate(., azimuth = calc_azimuth_circ_mean(.)))
  return(az_df)
})

# Format channel orientation table
flines_azimuth_df <- do.call("rbind", flines_azimuth) %>%
  select(huc8_id, azimuth) %>%
  # add huc8 name to this table
  left_join(huc8_tbl, by = "huc8_id") %>%
  # define order of huc8's
  mutate(huc8_name_ord = factor(huc8_name, 
                           levels = c("Lower John Day","Middle Platte-Prairie",
                                      "Teton","Upper Ochlockonee","Upper Delaware",
                                      "Salt","Little Miami","Puyallup","South Branch Potomac",
                                      "Atchafalaya","Lower San Pedro","Cuyahoga"))) %>%
  relocate(geometry, .after = last_col())


# Create grid containing channel orientation plots

# A couple steps so that coord_polar will allow free scales for facets, 
# grabbed from https://github.com/tidyverse/ggplot2/issues/2815
cp <- coord_polar()
cp$is_free <- function() TRUE

azimuth_grid <- ggplot(flines_azimuth_df, aes(x = azimuth)) + 
  geom_histogram(binwidth = 10, center = 5,
                 fill = "#08519c", color="#2171b5",
                 size = 0.25) +
  cp + facet_wrap(~ huc8_name_ord, scales = "free_y") +
  scale_x_continuous(expand = c(0,0),
                     breaks = seq(0, 360, by = 45),
                     minor_breaks = seq(0, 360, by = 15),
                     limits = c(0,360)) + 
  theme_bw() + 
  theme(aspect.ratio = 1,
        rect = element_blank(),
        plot.title = element_text(hjust = 0.5),
        axis.title = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank())


