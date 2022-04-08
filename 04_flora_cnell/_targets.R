library(targets)

options(tidyverse.quiet = TRUE)
tar_option_set(packages = c('tidyverse', 'rnpn', 'terra', 'raster', 'sf', 'colorspace'))

source("src/data_utils.R")
source("src/plot_utils.R")

proj <- "+proj=lcc +lat_1=30.7 +lat_2=29.3 +lat_0=28.5 +lon_0=-91.33333333333333 +x_0=999999.9999898402 +y_0=0 +ellps=GRS80 +datum=NAD83 +to_meter=0.3048006096012192 +no_defs"
proj_aea <- '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m no_defs'

list(
  tar_target(
    npn_layers, 
    npn_get_layer_details()
 ),
 tar_target(
    today,
    Sys.Date()
 ),
 tar_target(
   # most current daily anomaly
   daily_anomaly,
   get_npn_layer(layer_name = "Spring Indices, Daily Anomaly - Daily Spring Index Leaf Anomaly",
                 npn_layers,
                 layer_date = today),
   format = 'file'
  ),
 tar_target(
   # current date leaf out timing
   daily_timing,
   get_npn_layer(layer_name = "Spring Indices, Current Year - First Leaf - Spring Index",
                 npn_layers,
                 layer_date = today),
   format = 'file'
 ),
 tar_target(
   # historic date leaf out timing
   hist_data,{
     file_out <- 'out/si-x_30yr_avg_4k_leaf.tiff'
     layer_name <- "Spring Indices, 30-Year Average - 30-year Average SI-x First Leaf Date"
     layer_id <- npn_layers %>% 
       filter(title == layer_name) %>%
       pull(name)
     npn_download_geospatial(coverage_id = layer_id,
                           date = NULL,
                           format = 'geotiff',
                           output_path = file_out)
     return(file_out)
     },
   format = 'file'
 ),
 tar_target(
   # current date anomaly from 30-yr record
   # prep raster data - round to integers, calculate raster area, convert to df
   # don't worry about the error messages!
    spring_timing, 
    munge_npn_data(daily_timing, proj_aea)
 ),
 tar_target(
   # 30-yr historic average
   # prep raster data - round to integers, calculate raster area, convert to df
   # don't worry about the error messages!
   hist_timing, 
   munge_npn_data(hist_data, proj_aea)
 ),
 tar_target(
   # current date anomaly
    # prep raster data - round to integers, calculate raster area, convert to df
    # don't worry about the error messages!
    spring_anomaly, 
   munge_npn_data(daily_anomaly, proj_aea)
 ),
 tar_target(
   spring_index_png,
   plot_spring_index(spring_timing, 
                     proj_aea,
                      file_out = sprintf('out/spring_index_%s.png', today)),
   format = 'file'
 ),
 tar_target(
   spring_steps_png,
   plot_spring_steps(spring_timing, hist_timing,
                     proj = proj_aea,
                     file_out = sprintf('out/spring_steps_%s.png', today)),
   format = 'file'
 ),
 tar_target(
   spring_anomaly_early_png,
   plot_spring_anomaly(period = 'early',
                       spring_anomaly, 
                     proj_aea,
                     file_out = sprintf('out/spring_anomaly_%s.png', 'early'),
                     color_breaks = c(-4, -3, -2, -1, 0),
                     n_breaks = 4,
                     color_pal = c("white", "yellow","gold2", "darkgoldenrod4"),
                     color_limits = c(-4, 0)),
   format = 'file'
 ),
 tar_target(
   spring_anomaly_late_png,
   plot_spring_anomaly(period = 'late',
                       spring_anomaly, 
                       proj_aea,
                       file_out = sprintf('out/spring_anomaly_%s.png', 'late'),
                       color_breaks = c(0, 1, 2, 3),
                       n_breaks = 3,
                       color_pal = rev(c("white","thistle","mediumorchid","mediumpurple4")),
                       color_limits = c(0,3)),
   format = 'file'
 ),
 tar_target(
   anomaly_steps_png,
   plot_anomaly_steps(spring_anomaly,
                     proj = proj_aea,
                     file_out = sprintf('out/anomaly_steps_%s.png', today)),
   format = 'file'
 )
)
