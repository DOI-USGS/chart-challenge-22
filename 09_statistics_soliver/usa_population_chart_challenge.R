
# Relating gage locations to population density ---------------------------

library(raster)
library(sf)
library(rgdal)
library(tidyverse)
library(spData)
# Get data ----------------------------------------------------------------

# Download global gridded population data from: https://sedac.ciesin.columbia.edu/data/set/gpw-v4-population-count-rev11/data-download
# need to create account and log in, and I selected 2020, tif, 30 second resolution
# unzip folder into "in_dat"
in_file <- 'in_dat/gpw-v4-population-count-rev11_2020_30_sec_tif/gpw_v4_population_count_rev11_2020_30_sec.tif'
GDALinfo(in_file)
world <- raster(in_file) 

# create state file
states50 <- bind_rows(spData::us_states, spData::alaska, spData::hawaii) 
states <- spData::us_states 
states_buff <- states %>% st_buffer(1000000) # to extend map outside of USA on canvas

# crop raster data to states
pop_usa <- crop(world, extent(states_buff))
pop_lower <- crop(world, states)

# download gage information from S3 bucket "national-flow-observations"
# that is where products from this pipeline are pushed: https://github.com/USGS-R/national-flow-observations
# extract raster value at points
download.file('https://labs.waterdata.usgs.gov/visualizations/data/active_flow_gages_summary.rds', 'in_dat/active_flow_gages_summary.rds')
gages <- readRDS('in_dat/active_flow_gages_summary.rds')

# gages active in 2020 which matches year of population estimates
gages_2020 <- rowwise(gages) %>%
  filter(2020 %in% unlist(which_years_active))

# inventories for lat long associated with each site
download.file('https://labs.waterdata.usgs.gov/visualizations/data/nwis_dv_inventory.rds', 'in_dat/nwis_dv_inventory.rds')
download.file('https://labs.waterdata.usgs.gov/visualizations/data/nwis_uv_inventory.rds', 'in_dat/nwis_uv_inventory.rds')

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

# Proximity to gages ------------------------------------------------------

# how many people can walk/bike/drive to a gage in ~15 minutes?
# estimated this to be roughly <2km for walking, <6km for biking, <15km for driving

# one concern is double counting population for gages near eachother
# remove grid cells that are duplicated in the return from different gages
get_pop_by_dist <- function(gage_dist){
  buffer_dist <- gage_dist*1000 # convert km to m
  gages_2020_all$pop <- raster::extract(pop_usa, gages_2020_all, buffer = buffer_dist, cellnumbers = TRUE)
  walkcells <- as.data.frame(do.call(rbind, gages_2020_all$pop)) %>%
    distinct()
  sum(walkcells$value, na.rm = TRUE)
}

# find population within 1 km bands of gages 
dist_gage <- seq(1000, 100000, by= 1000)
dist_gage_pop <- lapply(dist_gage, function(x)get_pop(x)) # this takes a while to run >20 min
gage_dist <- data.frame(dist = do.call(rbind, dist_gage_pop), grid = dist_gage)

gage_dist %>%
  ggplot(aes(x = grid, y = dist/1000)) +
  geom_path(size = 1.5, color = "white") +
  geom_segment(data = gage_dist %>%
                    filter(grid %in% c(2000, 6000, 20000)),
             aes(y = dist/1000, yend = dist/1000,
                 x = 0, xend = grid),
             linetype = "dotted",
             size =1 ,
             color = "white") +
  geom_segment(data = gage_dist %>%
                 filter(grid %in% c(1000,2000,3000, 6000, 20000)),
               aes(x = grid, xend = grid,
                   y = 0, yend = dist/1000),
               linetype = "dotted",
               size = 1, 
               color = "white") +
  theme_classic(base_size = 40) +
  scale_y_continuous(
    breaks = scales::breaks_pretty(),
    labels = scales::label_number_si(),
    expand = c(0,0)
  ) +
  scale_x_continuous(
    breaks = scales::breaks_pretty(),
    labels = scales::label_number(scale = 1/1000, suffix = "km"),
    expand = c(0,0)
  ) +
  labs(x = "Distance from gage",
       y = "Total population") +
  geom_point(data = gage_dist %>%
               filter(grid %in% c(2000, 6000, 20000)),
             color = "white",
             size = 5,
             stroke = 1.5,
             shape = 21, 
             fill = "black")+
  theme(
    #axis.title = element_text(hjust = 0, vjust = -1, color = "white"),
    axis.title = element_blank(),
    axis.text = element_text(hjust = 0, color = "white"),
    axis.ticks = element_blank(),
    axis.line = element_line(color = "white"),
    plot.background = element_rect(fill = NA, color = NA),
    panel.background = element_rect(fill = NA, color = NA)
  )+
  coord_cartesian(clip = "off")

ggsave('out/distance_dist.png', width = 16, height = 6)


# Plot population and gage locations --------------------------------------

# there are many <1 values, which create negative orders of magnitude
# on the log scale. Turn these all into zeros
usa_dat <- as.data.frame(pop_usa, xy = TRUE)
state_dat <- as.data.frame(states, xy = TRUE)

p <- ggplot() +
  geom_raster(data = usa_dat, 
              aes(x = x, y = y,
                  fill = gpw_v4_population_count_rev11_2020_30_sec)) +
  geom_sf(data = states, fill = NA, color = 'gray20') +
  geom_sf(data = gages_2020_low, 
          #color = '#31ba1c', 
          color = "cyan",
          size = 0.1, 
          shape = 21,
          alpha = 0.5) +
 scale_fill_viridis_c(na.value = 'black',
                      option = 'B', 
                      breaks = c(1, 100, 1000, 10000, 100000),
                      trans = "log1p",
                      #breaks = scales::breaks_pretty(),
                      #labels = scales::label_number_si(),
                      # leave a little room for the NAs and Inf (which are 0s)
                      # to be darker than the -1 values
                      labels = c(1, 100, '1k', '10k', '100k'), 
                     begin = 0.05) +
  labs(fill = 'Population') +
  theme(plot.background = element_rect(fill = "black", color = "black"),
        panel.background = element_rect(fill = NA, color = NA),
        axis.title = element_blank(), 
        axis.text = element_blank(), 
        axis.ticks = element_blank(), 
        panel.grid = element_blank(),
        legend.background = element_blank()) +
  guides(fill = guide_colorbar(
    direction = "horizontal",
    title = "Population (per km2)",
    barwidth = 15, 
    title.position = "top",
    title.theme = element_text(color = "white"),
    label.theme = element_text(color = "white")
    
  )) 
p

ggsave('out/usa_population_sites.png', p, height = 12, width = 20)


# Plot population within buffer of gages by dist --------------------------

# given 1 km distances, how many people are within band for each gage?
ppl_by_dist <- function(gage_dist){
  
  dist_km <- 1000*gage_dist
  gages_2020_all$pop_dist <- raster::extract(pop_usa, gages_2020_all, buffer = dist_km, cellnumbers = TRUE)
  
  dist_df <- gages_2020_all %>%
    select(site, pop_dist)%>%
    unnest_longer(pop_dist, "pop") 
  
  site_dist <- dist_df %>% 
    select(site) %>%
    mutate(cell = dist_dfk$pop[,1], pop = dist_df$pop[,2]) %>%
    group_by(site) %>%
    summarize(pop_walk = sum(pop)) %>%
    mutate(dist_km = dist_km)
  
  return(site_dist)
}

km1 <- ppl_by_dist(1)

# do for range of distances

# Plot beeswarms ----------------------------------------------------------

km1 %>%
  ggplot(aes(dist_km, pop_walk)) +
  geom_beeswarm(side = 1L) +
  #geom_quasirandom()+
  #scale_y_continuous(trans = "log10")+
  coord_flip()+
  theme_classic()+
  theme(
    axis.line.y = element_blank(),
    axis.title.y = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank()
  )


