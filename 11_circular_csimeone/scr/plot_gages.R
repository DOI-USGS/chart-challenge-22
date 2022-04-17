# Plot gage locations

library(tibble)
library(dplyr)
library(stringr)
library(ggplot2)
library(cowplot)
library(sf)
library(maptools)
library(ggmap)
library(tigris)

# Load Site List
load("data_in/site_list.RData")

# Read in metadata for plotting. 
# gages 2 metadata can be found here: https://www.sciencebase.gov/catalog/item/59692a64e4b0d1f9f05fbd39
loc_df <- read.csv("data_in/NWIS_data/gagesII_metadata.csv",header=TRUE,stringsAsFactors = FALSE) %>%
  mutate(StaID = str_pad(STAID, width=8, side="left", pad = "0")) %>%
  as_tibble() %>%
  rename(site = StaID, latitude = LAT_GAGE, longitude = LNG_GAGE) %>%
  select(c(site, latitude, longitude, HUC02)) %>%
  filter(site %in% site_list)

# Set site data as a simple feature. 
loc_sf <- st_as_sf(loc_df, coords = c("longitude", "latitude"), 
                   crs = 4326)

# Pull in data for plotting US states
us_geo <- tigris::states(class = "sf", cb = TRUE) %>% 
  shift_geometry() %>% 
  filter(GEOID < 60) %>%
  filter(!STUSPS %in% c("HI", "AK"))


# Basin shapefiles can be downloaded here. 
# https://apps.nationalmap.gov/downloader/#/
sh_14 <- sf::st_read("data_in/Shapefiles/HUC_14/WBDHU2.shp")
sh_f_14 <- fortify(sh_14)
sh_f_5070_14 <- st_transform(sh_f_14, 5070)[1]

sh_15 <- sf::st_read("data_in/Shapefiles/HUC_15/WBDHU2.shp")
sh_f_15 <- fortify(sh_15)
sh_f_5070_15 <- st_transform(sh_f_15, 5070)[1]

# Plot Figure
p_1 <- us_geo %>%
  ggplot() +
  geom_sf() +
  coord_sf(crs = 5070, datum = NA) +  
  geom_sf(data = loc_sf, inherit.aes = FALSE, fill = NA, size = 2) +
  geom_sf(data = sh_f_5070_15, inherit.aes = FALSE, fill = NA, color = 'red', size = 1) +
  geom_sf(data = sh_f_5070_14, inherit.aes = FALSE, fill = NA, color = 'blue', size = 1) +
  theme_minimal()

fig_text <- "USGS Gages II gages used in the US wide plot and the boundaries of the upper (blue) and 
lower (red) Colorado River Basin. The density of gages is much higher in some parts of the 
country like the east coast and lower in much of the center west of the country. The Colorado Basin 
plot only uses data from 1981-2020 partly because of the lack of gages in the lower basin the reach 1951"

p_2 <- ggdraw() +
  draw_plot(p_1 , x=-0.05, y = -0.1, width = 1.1, height = 1.2 ) + 
  draw_text(fig_text, x = 0.5, y = 0.1, size = 12)

p_2

ggsave(plot = p_2, "viz/Map_of_Gages.png", width = 8, height = 8)
