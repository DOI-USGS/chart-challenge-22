plot_temp_diff <- function(fileout, early_data, late_data){



  del_data <- late_data %>% rename(late_GDD_time = GDD_time, late_GDD_mean = GDD_mean) %>%
    st_join(early_data) %>%
    mutate(GDD_timing_diff = late_GDD_time - GDD_time,
           GDD_mean_diff = late_GDD_mean - GDD_mean) %>%
    mutate(x = st_coordinates(.)[,1], y = st_coordinates(.)[,2],
           x_dif = GDD_timing_diff*10000,
           y_dif = GDD_mean_diff*200,
           xend = x - x_dif,
           yend = y + y_dif,
           angle = (atan2(y_dif,x_dif)*180)/pi) %>%
    st_drop_geometry()

  ggplot() +
    coord_sf(crs = st_crs(early_data)) +
    geom_segment(del_data, mapping = aes(col = angle, x = x, y = y, xend = xend, yend = yend),
                 size = 0.2) +
    scale_colour_viridis_c(option = "magma", direction = -1)

  ggsave(filename = fileout, width = 16, height = 10)


}
