library(targets)

tar_option_set(packages = c(
  "tidyverse",
  "ncdf4",
  "lubridate",
  "sf",
  "data.table",
  "spData",
  "sbtools"
))

source("src/data_utils.R")
source("src/plot_utils.R")

list(

  ## Download files from ScienceBase (SB)
  tar_target(data_sb_id, '60341c3ed34eb12031172aa6'),
  tar_target(predicted_temp_filenames,
             find_sb_files(
               sb_id = data_sb_id,
               pattern = "_predicted_temp_(.+).nc")
  ),
  tar_target(predicted_temp_ncs,
             download_sb_files(
               sb_id = data_sb_id,
               sb_filenames = predicted_temp_filenames,
               out_dir = 'data_in'),
             format="file"),

  ## Prep data
  tar_target(early_data, summarize_nc_time(year0 = 1981, year1 = 1990, predicted_temp_ncs)),
  tar_target(late_data, summarize_nc_time(year0 = 2011, year1 = 2020, predicted_temp_ncs)),

  ## Create visuals
  tar_target(date_map_vectors_png, plot_temp_diff('viz/220403_map_vectors.png', early_data, late_data), format = "file"),
  tar_target(legend_radial_png, make_legend('viz/legend_radial.png', pie_slices = 12), format="file")

)
