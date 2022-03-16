plot_temp_diff <- function(fileout, early_data, late_data){
  del_data <- late_data %>% rename(late_temp = surftemp) %>%
    st_join(early_data) %>% mutate(temp_diff = late_temp - surftemp)

  ggplot() +
    geom_sf(data = del_data, size = 0.5, aes(col=temp_diff)) +
    scale_colour_viridis_c(option = "magma")

  ggsave(filename = fileout)


}
