library(targets)

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c('tidyverse', 'rvest', 'spData', 'sf', 'cartogram',
                            'showtext', 'scico', 'gganimate', 'transformr'))

source("src/data_utils.R")
source("src/plot_utils.R")

wss_url <- 'https://www.usgs.gov/special-topics/water-science-school/science/how-wet-your-state-water-area-each-state'
proj_aea <- '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m no_defs'

list(
  tar_target(
    state_file, 
    scrape_table('out/state_water_area.csv', wss_url),
    format = "file"
  ),
  tar_target(
    states,
    spData::us_states %>% st_transform(proj_aea)
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
    combine_states(state_data, carto_data)
  ),
  tar_target(
    water_area_gif,
    morph_maps(file_out = 'out/water_area.gif', transition_df),
    format = 'file'
  ),
  tar_target(
    water_area_rank_png,
    plot_area_rank('out/water_rank.png', transition_df),
    format = 'file'
  )
)