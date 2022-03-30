library(targets)
library(tidyverse)
library(rvest)
library(spData)
library(sf)
library(cartogram)
library(showtext)
library(scico)
library(gganimate)

options(tidyverse.quiet = TRUE)

source("src/data_utils.R")
source("src/plot_utils.R")

wss_url <- 'https://www.usgs.gov/special-topics/water-science-school/science/how-wet-your-state-water-area-each-state'
proj <- "+proj=lcc +lat_1=30.7 +lat_2=29.3 +lat_0=28.5 +lon_0=-91.33333333333333 +x_0=999999.9999898402 +y_0=0 +ellps=GRS80 +datum=NAD83 +to_meter=0.3048006096012192 +no_defs"

list(
  tar_target(
    state_file, 
    scrape_table('in/state_water_area.csv', wss_url),
    format = "file"
  ),
  tar_target(
    states,
    spData::us_states %>% st_transform(proj)
  ),
  tar_target(
    state_data,
    prep_data(states, state_file)
  ),
  tar_target(
    carto_data,
    cartogram_cont(state_data, weight = 'inland_perc')
  ),
  tar_target(
    transition_df,
    transition_states(state_data, carto_data)
  ),
  tar_target(
    water_area_gif,
    morph_maps(file_out = 'out/water_area.gif', transition_df)
  ),
  tar_target(
    water_area_rank_png,
    plot_ara_rank('out/water_rank.png', transition_df)
  )
)