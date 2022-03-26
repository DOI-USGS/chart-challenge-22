

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
    time_idx <- which(time %in% use_times)

    lake_lat <-  ncvar_get(nc, 'lat')
    lake_lon <-  ncvar_get(nc, 'lon')

    # create a year group, and calculate information for each
    # verify use_times is identical order to actual times!!
    yyyy_groups <- lubridate::year(use_times)

    nc_as_DT <- as.data.table(
      ncvar_get(nc, 'surftemp', start = c(first(time_idx), 1),
                          count = c(last(time_idx) - first(time_idx) + 1, -1))
    )

    DT_grouped <- nc_as_DT[, group_value := yyyy_groups]
    DT_melted <- melt(DT_grouped, id.vars = "group_value", variable.name = "lake_id", value.name = "daily_temp")[, .(
      GDD = sum(daily_temp, na.rm = TRUE),
      GDD_doy = which.min(abs(cumsum(daily_temp) - sum(daily_temp)*0.5))
    ), by = list(group_value, lake_id)]


    data_out <- DT_melted[, .(
      GDD_mean = mean(GDD),
      GDD_doy_mean = mean(GDD_doy)), by = list(lake_id)] %>%
      as_tibble() %>%
      mutate(lat = lake_lat, lon = lake_lon) %>%
      select(-lake_id)

    nc_close(nc)
    message('.')
    data_out
  }) %>% bind_rows() %>%
    st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
    st_transform("+proj=lcc +lat_1=30.7 +lat_2=29.3 +lat_0=28.5 +lon_0=-91.33333333333333 +x_0=999999.9999898402 +y_0=0 +ellps=GRS80 +datum=NAD83 +to_meter=0.3048006096012192 +no_defs")

}
