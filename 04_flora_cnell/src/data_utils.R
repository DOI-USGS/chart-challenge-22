get_npn_layer <- function(layer_name, npn_layers, layer_date){
  
  layer_id <- npn_layers %>% 
    filter(title == layer_name) %>%
    pull(name)

  if(!is.null(layer_date)){
    label_date <- 'avg'
  } else{
    label_date <- layer_date
  }
  file_out <- gsub(':', '_', sprintf('out/%s_%s.tiff', layer_id, label_date))
  npn_download_geospatial(coverage_id = layer_id,
                          date = layer_date,
                          format = 'geotiff',
                          output_path = file_out
  )
  
  return(file_out)
  
}
munge_npn_data <- function(current_timing, proj){
  anomaly_rast <- rast(current_timing) %>%
    project(y = proj)
  
  # round to day
  values(anomaly_rast) <- round(values(anomaly_rast), 0)
  
  # calculate area of each grid cell
  anom_area <- cellSize(anomaly_rast, unit = "km")
  anom_stack<- stack(c(anomaly_rast, anom_area))
  
  # convert to df
  anom_df <- anom_stack %>%  
    as.data.frame(xy = TRUE) %>% 
    rename(timing = 3) %>%
    mutate(timing_day = round(timing, 0))
}