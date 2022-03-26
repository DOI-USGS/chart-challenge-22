plot_temp_diff <- function(fileout, early_data, late_data){

  # CRS-specific scaling for vectors and cells.
  cell_size <- 60000
  y_scale <- 250

  # scale agnostic params
  x_y_ratio <- 75
  x_scale <- x_y_ratio * y_scale
  lwd <- 0.3

  # going to resample this to a hex grid so it isn't too busy:
  site_grid <- st_make_grid(early_data, cellsize = cell_size, square = FALSE, offset = c(-125, 25)) %>%
    st_as_sf() %>%
    select(geometry=x) %>%
    mutate(cell_id = row_number()) %>%
    st_transform(st_crs(early_data))

  # make a vector that is straight up and large:
  late_data[3000,]$GDD_mean <- late_data[3000,]$GDD_mean + 100000
  late_data[3000,]$GDD_doy_mean <- early_data[3000,]$GDD_doy_mean

  # make a vector that is to the right and large:
  late_data[2,]$GDD_mean <- early_data[2,]$GDD_mean
  late_data[2,]$GDD_doy_mean <- late_data[2,]$GDD_doy_mean + 500

  # make a vector that is to the left and large:
  late_data[6000,]$GDD_mean <- early_data[6000,]$GDD_mean
  late_data[6000,]$GDD_doy_mean <- late_data[6000,]$GDD_doy_mean - 500

  del_data <- late_data %>% rename(late_GDD_doy = GDD_doy_mean, late_GDD_mean = GDD_mean) %>%
    st_join(early_data) %>%
    mutate(GDD_timing_diff = late_GDD_doy - GDD_doy_mean,
           GDD_mean_diff = late_GDD_mean - GDD_mean) %>%
    mutate(x = st_coordinates(.)[,1], y = st_coordinates(.)[,2],
           x_dif = GDD_timing_diff * x_scale,
           y_dif = GDD_mean_diff*y_scale,
           xend = x - x_dif,
           yend = y + y_dif) %>%
    st_intersection(site_grid, .) %>%
    group_by(cell_id) %>%
    st_drop_geometry() %>%
    summarize_all(mean) %>%
    mutate(angle = (atan2(y_dif,x_dif)*180)/pi)

  US_states <- sf::st_transform(spData::us_states, st_crs(early_data))

  ggplot() +
    geom_sf(data = US_states, color = 'grey90', fill = 'white', size = 0.75) +
    geom_segment(del_data, mapping = aes(col = angle, x = x, y = y, xend = xend, yend = yend),
                 size = lwd) +
    scico::scale_color_scico(palette = "romaO", direction = -1)

  ggsave(filename = fileout, width = 16, height = 10)


}
