

summarize_nc_time <- function(year0, year1, mm_dd0, mm_dd1, ...){

  # this assumes you downloaded files from https://doi.org/10.5066/P9CEMS0M
  data_files <- as_data_file(c(...))
  if (any(!file.exists(data_files))){
    stop('need to download .nc files from https://doi.org/10.5066/P9CEMS0M')
  }

  use_times <- purrr::map(year0:year1, function(yy){
    seq(as.Date(sprintf('%s-%s', yy, mm_dd0)), to = as.Date(sprintf('%s-%s', yy, mm_dd1)), by = 'days')
  }) %>% unlist() %>% as_date()

  # for sampling
  set.seed(1)

  summarized_data <- purrr::map(data_files, function(pred_fl){
    nc <- nc_open(pred_fl)
    time_origin <- ncdf4::ncatt_get(nc, 'time', attname = 'units')$value %>% str_remove("days since ")
    time <- ncvar_get(nc, 'time') + as.Date(time_origin)
    time_idx <- which(time %in% use_times)

    site_ids <- ncvar_get(nc, 'site_id')

    lake_lat <-  ncvar_get(nc, 'lat')
    lake_lon <-  ncvar_get(nc, 'lon')

    use_idx <- sample(1:length(lake_lat), size = 10000)

    # create a year group, and calculate information for each
    # verify use_times is identical order to actual times!!
    yyyy_groups <- lubridate::year(use_times)

    data_out <- ncvar_get(nc, 'surftemp', start = c(first(time_idx), 1),
                          count = c(last(time_idx) - first(time_idx) + 1, -1)) %>%
      {.[, use_idx]} %>% as_tibble(.name_repair = 'unique') %>%
      # would it be better to pivot longer here?
      mutate(group_values = yyyy_groups) %>%
      group_by(group_values) %>%
      # find index of day when it is the percentage of GDD
      # need to make this GDD instead of just a rolling sum:
      summarize_all(.funs = list(GDD_time = ~ which.min(abs(cumsum(.) - sum(.)*0.5)),
                                 GDD_mean = ~ sum(.))) %>%
      select(-group_values) %>%
      ungroup() %>%
      # take the mean of all years in the collection
      summarize_all(.funs = mean) %>%
      pivot_longer(everything(), names_pattern =  '(.*)(GDD_time|GDD_mean)', names_to = c('site_id','stat')) %>%
      pivot_wider(names_from = stat, values_from = value) %>%
      mutate(lat = lake_lat[use_idx], lon = lake_lon[use_idx]) %>%
      select(-site_id)


    nc_close(nc)
    data_out
  }) %>% bind_rows() %>%
    st_as_sf(coords = c("lon", "lat"), crs = 4326) %>%
    st_transform("+proj=lcc +lat_1=30.7 +lat_2=29.3 +lat_0=28.5 +lon_0=-91.33333333333333 +x_0=999999.9999898402 +y_0=0 +ellps=GRS80 +datum=NAD83 +to_meter=0.3048006096012192 +no_defs")

}
