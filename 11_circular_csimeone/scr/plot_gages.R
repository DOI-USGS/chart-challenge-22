# Plot gage locations

library(tibble)
library(dplyr)
library(stringr)
library("ggplot2")
library("cowplot")
library(sf)
library(maptools)
library(ggmap)

# library(tidyverse)       
# library(readxl)
library(tigris)
# library(sf)
# library(viridis)

load("11_circular_csimeone/data_in/site_list.RData")

# Read in metadata for plotting. 
# gages 2 metadata can be found here: https://www.sciencebase.gov/catalog/item/59692a64e4b0d1f9f05fbd39
loc_df <- read.csv("11_circular_csimeone/data_in/NWIS_data/gagesII_metadata.csv",header=TRUE,stringsAsFactors = FALSE) %>%
  mutate(StaID = str_pad(STAID, width=8, side="left", pad = "0")) %>%
  as_tibble() %>%
  rename(site = StaID, latitude = LAT_GAGE, longitude = LNG_GAGE) %>%
  select(c(site, latitude, longitude, HUC02)) %>%
  filter(site %in% site_list)

# # Basin shapefiles can be downloaded here. 
# # https://apps.nationalmap.gov/downloader/#/
# sh_14 <- sf::st_read("11_circular_csimeone/data_in/Shapefiles/HUC_14/WBDHU2.shp")
# sh_f_14 <- fortify(sh_14)
# sh_f_4326_14 <- st_transform(sh_f_14, 4326)[1]
# 
# sh_15 <- sf::st_read("11_circular_csimeone/data_in/Shapefiles/HUC_15/WBDHU2.shp")
# sh_f_15 <- fortify(sh_15)
# sh_f_4326_15 <- st_transform(sh_f_15, 4326)[1]
# 
# bbox <- c(left = -125, bottom = 25, right = -67, top = 50)
# us <- c(left = -125, bottom = 25.75, right = -67, top = 49)
# 
# 
# # site_map = ggmap(get_stamenmap(bbox, maptype = "terrain-background", zoom = 4))+
# site_map <- ggmap(get_stamenmap(us, zoom = 5, maptype = "toner-lite")) + 
#   geom_sf(data = sh_f_4326_14, inherit.aes = FALSE, fill = NA, size = 2) +
#   geom_sf(data = sh_f_4326_15, inherit.aes = FALSE, fill = NA, size = 2) +
#   geom_point(data = loc_df, aes(x = longitude, latitude),
#              size = 1.5)+
#   theme_bw() +
#   scale_colour_gradientn(colours = rev(my.palette),
#                          limits = c(-100, 100), 
#                          oob = scales::squish) +
#   labs(x = "Longitude", y = "Latitude")
# site_map
# 
# site_map <- ggmap(data=us, map=us,aes(x=long, y=lat, map_id=region, group=group),
#                   fill="#ffffff", color="#7f7f7f", size=0.5) + 
#   geom_sf(data = sh_f_4326_14, inherit.aes = FALSE, fill = NA, size = 2) +
#   geom_sf(data = sh_f_4326_15, inherit.aes = FALSE, fill = NA, size = 2) +
#   geom_point(data = loc_df, aes(x = longitude, latitude),
#              size = 1.5)+
#   theme_bw() +
#   scale_colour_gradientn(colours = rev(my.palette),
#                          limits = c(-100, 100), 
#                          oob = scales::squish) +
#   labs(x = "Longitude", y = "Latitude")
# site_map
# 
# us <- map_data("state")
# us <- fortify(us, region="region")
# 
# p <- ggplot() + 
#   geom_map(data=us, map=us,aes(x=long, y=lat, map_id=region, group=group),
#            fill="#ffffff", color="#7f7f7f", size=0.5) + 
#   geom_point(data = loc_df, aes(x=longitude, y=latitude)) + 
#   coord_map("albers", lat0=39, lat1=45)+ 
#   # coord_map('conic', lat0=30) +
#   theme_map() +
#   theme(legend.position = c(0.75, 0.3), plot.margin=unit(c(0,0,0,00),"mm")) 
# p




loc_sf <- st_as_sf(loc_df, coords = c("longitude", "latitude"), 
                   crs = 4326)

us_geo <- tigris::states(class = "sf", cb = TRUE) %>% 
  shift_geometry() %>% 
  filter(GEOID < 60) %>%
  filter(!STUSPS %in% c("HI", "AK"))

sh_14 <- sf::st_read("11_circular_csimeone/data_in/Shapefiles/HUC_14/WBDHU2.shp")
sh_f_14 <- fortify(sh_14)
sh_f_5070_14 <- st_transform(sh_f_14, 5070)[1]

sh_15 <- sf::st_read("11_circular_csimeone/data_in/Shapefiles/HUC_15/WBDHU2.shp")
sh_f_15 <- fortify(sh_15)
sh_f_5070_15 <- st_transform(sh_f_15, 5070)[1]

p_1 <- us_geo %>%
  ggplot() +
  geom_sf() +
  coord_sf(crs = 5070, datum = NA) +  
  geom_sf(data = loc_sf, inherit.aes = FALSE, fill = NA, size = 2) +
  geom_sf(data = sh_f_5070_15, inherit.aes = FALSE, fill = NA, color = 'red', size = 1) +
  geom_sf(data = sh_f_5070_14, inherit.aes = FALSE, fill = NA, color = 'blue', size = 1) +
  theme_minimal()
  # geom_point(data = loc_sf, aes(x=longitude, y=latitude)) 

fig_text <- "USGS Gages II gages used in the US wide plot and the boundaries of the upper (blue) and 
lower (red) Colorado River Basin. The density of gages is much higher in some parts of the 
country like the east coast and lower in much of the center west of the country. The Colorado Basin 
plot only uses data from 1981-2020 partly because of the lack of gages in the lower basin the reach 1951"

p_2 <- ggdraw() +
  draw_plot(p_1 , x=-0.05, y = -0.1, width = 1.1, height = 1.2 ) + 
  draw_text(fig_text, x = 0.5, y = 0.1, size = 12)

p_2

ggsave(plot = p_2, "11_circular_csimeone/viz/Map_of_Gages.png", width = 8, height = 8)
