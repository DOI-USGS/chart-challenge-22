plot_temp_diff <- function(fileout, early_data, late_data){

  # CRS-specific scaling for vectors and cells.
  cell_size <- 60000 # smaller number for finer resolution = more busy
  y_scale <- 300 # smaller number for shorter vectors

  # scale agnostic params:
  x_y_ratio <- 75 # relationship between x and y components, since they are diff units
  x_scale <- x_y_ratio * y_scale
  lwd <- 0.35 # line width for vectors

  # going to resample this to a hex grid so it isn't too busy:
  site_grid <- st_make_grid(early_data, cellsize = cell_size, square = FALSE, offset = c(-125, 25)) %>%
    st_as_sf() %>%
    select(geometry=x) %>%
    mutate(cell_id = row_number()) %>%
    st_transform(st_crs(early_data))

  del_data <- late_data %>% rename(late_GDD_doy = GDD_doy_mean, late_GDD_mean = GDD_mean) %>%
    st_join(early_data) %>%
    # calculate the difference in timing and ave yearly GDD between the periods
    mutate(GDD_timing_diff = late_GDD_doy - GDD_doy_mean,
           GDD_mean_diff = late_GDD_mean - GDD_mean) %>%
    # calculate vectors for each lake
    mutate(x = st_coordinates(.)[,1], y = st_coordinates(.)[,2],
           x_dif = GDD_timing_diff * x_scale,
           y_dif = GDD_mean_diff*y_scale,
           xend = x + x_dif,
           yend = y + y_dif) %>%
    # group to cells, use averages within each cell to make it less busy
    st_intersection(site_grid, .) %>%
    group_by(cell_id) %>%
    st_drop_geometry() %>%
    summarize_all(mean) %>%
    # calc angle of cell-based vector, which is an ave of all lakes in cell:
    mutate(angle = (atan2(y_dif,x_dif)*180)/pi)

  # access Contiguous U.S. state map:
  US_states <- sf::st_transform(spData::us_states, st_crs(early_data))

  ggplot() +
    geom_sf(data = US_states, color = 'grey90', fill = 'white', size = 0.75) +
    geom_segment(del_data, mapping = aes(col = angle, x = x, y = y, xend = xend, yend = yend),
                 size = lwd, show.legend = FALSE) +
    scico::scale_color_scico(palette = "romaO", direction = -1,
                             begin = 0.05, end = 0.95) +
    labs(title = "Changes in temperature and timing for lakes in the contiguous U.S.",
         subtitle = "As quantified by comparing timing and magnitude of growing degree days, 1981-1990 vs 2011-2020; data from: doi.org/10.5066/P9CEMS0M") +
    theme_void()

  ggsave(filename = fileout, width = 16, height = 10)


}
make_legend <- function(fileout, pie_slices){

  legend_df <- tibble(val = seq(-180, 180-(360/(pie_slices)), by = 360/(pie_slices)),
                  label = as.factor(seq(1, pie_slices, by = 1)))


  legend_df %>%
    ggplot() +
    # make pie color ramp
    geom_tile(aes(x = 1,
                  y = val+(360/(pie_slices)/2), # geom_tile positions from center of tile
                  height = 360/(pie_slices),
                  fill = val), show.legend = FALSE) +
    coord_polar(theta="y", start = 90*(pi/180), direction = -1, clip = 'off') +
    # cap ends of color scale so purple is equally weighted
    scico::scale_fill_scico(palette = "romaO",
                            direction = -1,
                            begin = 0.05, end = 0.95)+
    # use scale expansion to create donut appearance
    scale_x_discrete(expand = expansion(mult = c(5.5, 0.75), add = 0)) +
    theme_void()

  ggsave(filename = fileout, width = 3, height = 3, dpi = 300)
}
