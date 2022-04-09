library(raster)
library(sf)
library(rgdal)
library(tidyverse)
library(spData)

# dowload global gridded population data from: https://sedac.ciesin.columbia.edu/data/set/gpw-v4-population-count-rev11/data-download
# need to lcreate account and log in, and I selected 2020, tif, 30 second resolution
# unzip folder into "in_dat"
in_file <- 'in_dat/gpw-v4-population-count-rev11_2020_30_sec_tif/gpw_v4_population_count_rev11_2020_30_sec.tif'
GDALinfo(in_file)
world <- raster(in_file) 

# create state file
states50 <- bind_rows(spData::us_states, spData::alaska, spData::hawaii)
states <- spData::us_states

# crop raster data to states
pop_usa <- crop(world, extent(states50))
pop_lower <- crop(world, extent(states))

# download gage information from S3 bucket "national-flow-observations"
# that is where products from this pipeline are pushed: https://github.com/USGS-R/national-flow-observations
# extract raster value at points
download.file('https://labs.waterdata.usgs.gov/visualizations/data/active_flow_gages_summary.rds', 'in_dat/active_flow_gages_summary.rds')
gages <- readRDS('in_dat/active_flow_gages_summary.rds')

# gages active in 2020 which matches year of population estimates
gages_2020 <- rowwise(gages) %>%
  filter(2020 %in% unlist(which_years_active))

# inventories for lat long associated with each site
sites <- readRDS('in_dat/nwis_dv_inventory.rds') %>%
  bind_rows(readRDS('in_dat/nwis_uv_inventory.rds')) %>%
  dplyr::select(site_no, station_nm, site_tp_cd, dec_lat_va, dec_long_va) %>%
  distinct()

# all gages for analysis purposes
gages_2020_all <- left_join(gages_2020, sites, by = c('site' = 'site_no')) %>%
  st_as_sf(coords = c('dec_long_va', 'dec_lat_va'), crs = 4326)

# gages in the lower 48 for map purposes
gages_2020_low <- left_join(gages_2020, sites, by = c('site' = 'site_no')) %>%
  filter(dec_lat_va < 50 & dec_lat_va > 24.5 & dec_long_va < -66 & dec_long_va > -125) %>%
  st_as_sf(coords = c('dec_long_va', 'dec_lat_va'), crs = 4326)

# how many people can walk/bike/drive to a gage in ~15 minutes?
# estimated this to be roughly <2km for walking, <6km for biking, <15km for driving

# one concern is double counting population for gages near eachother
# remove grid cells that are duplicated in the return from different gages

# walk - 1km buffer which will include people 0-2km away (grid is 1kmx1km)
# 6.6 million
gages_2020_all$walk_population_1km <- raster::extract(pop_usa, gages_2020_all, buffer = 1000, cellnumbers = TRUE)
walkcells <- as.data.frame(do.call(rbind, gages_2020_all$walk_population_1km)) %>%
  distinct()
sum(walkcells$value, na.rm = TRUE)

# how many people can bike to a gage? 104.1 million
# 5km buffer which is anywhere from 0 to 6km distance
gages_2020_all$bike_population_5km <- raster::extract(pop_usa, gages_2020_all, buffer = 5000, cellnumbers = TRUE)
bikecells <- as.data.frame(do.call(rbind, gages_2020_all$bike_population_5km)) %>%
  distinct()

sum(bikecells$value, na.rm = TRUE)

# how many people can drive to a gage in 15 minutes? 0 to 21km - 302.7 million
gages_2020_all$drive_population_20km <- raster::extract(pop_usa, gages_2020_all, buffer = 20000, cellnumbers = TRUE)
drivecells <- as.data.frame(do.call(rbind, gages_2020_all$drive_population_20km)) %>%
  distinct()

sum(drivecells$value, na.rm = TRUE)


# there are many <1 values, which create negative orders of magnitude
# on the log scale. Turn these all into zeros
usa_dat <- as.data.frame(pop_lower, xy = TRUE)
usa_dat$pop <- ifelse(usa_dat$gpw_v4_population_count_rev11_2020_30_sec < 1 & usa_dat$gpw_v4_population_count_rev11_2020_30_sec > 0, 0.1, usa_dat$gpw_v4_population_count_rev11_2020_30_sec)
usa_dat$pop_log10 <- log10(usa_dat$pop)
state_dat <- as.data.frame(states, xy = TRUE)

p <- ggplot() +
  geom_raster(data = usa_dat, aes(x = x, y = y, 
                                  fill = pop_log10)) +
  geom_sf(data = states, fill = NA, color = 'gray20') +
  geom_sf(data = gages_2020_low, color = '#31ba1c', size = 0.1, alpha = 0.5) +
  scale_fill_viridis_c(na.value = 'black', option = 'B', breaks = c(0, 1, 2, 3, 4, 5),
                       # leave a little room for the NAs and Inf (which are 0s)
                       # to be darker than the -1 values
                       labels = c(1, 10, 100, '1k', '10k', '100k'), begin = 0.05) +
  labs(fill = 'Population') +
  theme(plot.background = element_rect(fill = NA, color = NA),
        panel.background = element_rect(fill = NA, color = NA),
        axis.title = element_blank(), 
        axis.text = element_blank(), 
        axis.ticks = element_blank(), 
        panel.grid = element_blank(),
        legend.background = element_blank(),
        legend.text = element_text(color = 'gray68'))

ggsave('out/usa_population_sites.png', p, height = 6, width = 11)


