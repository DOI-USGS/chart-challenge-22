

summarize_nc_time <- function(year0, year1, mm_dd0, mm_dd1, ...){

  # this assumes you downloaded files from https://doi.org/10.5066/P9CEMS0M
  data_files <- as_data_file(c(...))
  if (any(!file.exists(data_files))){
    stop('need to download .nc files from https://doi.org/10.5066/P9CEMS0M')
  }

  use_times <- purrr::map(year0:year1, function(yy){
    seq(as.Date(sprintf('%s-%s', yy, mm_dd0)), to = as.Date(sprintf('%s-%s', yy, mm_dd1)), by = 'days')
  }) %>% unlist() %>% as_date()

  summarized_data <- purrr::map(data_files, function(pred_fl){
    nc <- nc_open(pred_fl)
    time_origin <- ncdf4::ncatt_get(nc, 'time', attname = 'units')$value %>% str_remove("days since ")
    time <- ncvar_get(nc, 'time') + as.Date(time_origin)
    time_idx <- time %in% use_times
    all_surftemp <- ncvar_get(nc, 'surftemp', start = c(1, 1), count = c(-1, -1)) %>%
      {.[time_idx, ]} %>% colMeans()

    lake_lat <-  ncvar_get(nc, 'lat')
    lake_lon <-  ncvar_get(nc, 'lon')
    nc_close(nc)
    tibble(surftemp = all_surftemp, lat = lake_lat, lon = lake_lon)
  }) %>% bind_rows() %>%
    st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
    st_transform("+proj=lcc +lat_1=30.7 +lat_2=29.3 +lat_0=28.5 +lon_0=-91.33333333333333 +x_0=999999.9999898402 +y_0=0 +ellps=GRS80 +datum=NAD83 +to_meter=0.3048006096012192 +no_defs")

}
