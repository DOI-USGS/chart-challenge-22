plot_temp_diff <- function(fileout, early_data, late_data){

  # CRS-specific scaling for vectors and cells.
  x_scale <- 10000
  y_scale <- 200
  cell_size <- 50000

  # going to resample this to a hex grid so it isn't too busy:
  site_grid <- st_make_grid(early_data, cellsize = cell_size, square = FALSE, offset = c(-125, 25)) %>%
    st_as_sf() %>%
    select(geometry=x) %>%
    mutate(cell_id = row_number()) %>%
    st_transform(st_crs(early_data))

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


  ggplot() +
    coord_sf(crs = st_crs(early_data)) +
    geom_segment(del_data, mapping = aes(col = angle, x = x, y = y, xend = xend, yend = yend),
                 size = 0.35) +
    scale_colour_viridis_c(option = "magma", direction = -1)

  ggsave(filename = fileout, width = 16, height = 10)


}
