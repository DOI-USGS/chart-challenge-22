library(targets)

tar_option_set(packages = c(
  "tidyverse",
  "ncdf4",
  "scipiper",
  "lubridate",
  "sf",
  "data.table",
  "spData"
))

source("src/data_utils.R")
source("src/plot_utils.R")

list(

  # Define input files
  tar_target(predicted_temp_ncs, list.files("data_in", pattern = "_predicted_temp_(.+).nc", full.names = T), format="file"),

  ## Prep data
  tar_target(early_data, summarize_nc_time(year0 = 1981, year1 = 1990, predicted_temp_ncs)),
  tar_target(late_data, summarize_nc_time(year0 = 2011, year1 = 2020, predicted_temp_ncs)),

  ## Create visuals
  tar_target(date_map_vectors_png, plot_temp_diff('viz/220403_map_vectors.png', early_data, late_data), format = "file"),
  tar_target(legend_radial_png, make_legend('viz/legend_radial.png', pie_slices = 12), format="file")

)
