plot_daily_anomaly <- function(daily_anomaly, proj, file_out){
  
  anomaly_rast <- rast(daily_anomaly) %>%
    project(y = proj)
  
  anomaly_df <- as.data.frame(anomaly_rast, xy=TRUE) %>% 
    rename(timing = 3) 
  
  anomaly_df %>%
    ggplot() +
    geom_tile(aes(x =x, y = y, fill = timing))+
    theme_void() +
    coord_fixed()+
    scale_fill_viridis_c(option = 'magma')
  
  ggsave(file_out)
  
  return(file_out)
}

plot_spring_index <- function(spring_timing, proj, file_out){
  

  # access Contiguous U.S. state map:
  state_map <- spData::us_states %>% st_transform(proj)
  
  spring_timing %>%
    ggplot() +
    geom_sf(data = state_map, fill = NA, color = "grey", alpha = 0.5) +
    geom_tile(aes(x =x, y = y, fill = timing_day),
              alpha = 0.8)+
    geom_sf(data = state_map%>%st_union(), fill = NA, color = "grey") +
    theme_void()+
    theme(
      plot.background = element_rect(fill = NA, color = NA),
      panel.background = element_rect(fill = NA, color = NA),
      plot.title = element_text(color = "white", size = 30, face = "bold"),
      plot.subtitle = element_text(color = "white"),
      legend.position = 'none')+
    coord_sf()+
    scale_fill_stepsn(colors = sequential_hcl(10, "TealGrn"),
                      "First leaf date",
                      na.value = NA,
                      show.limits = TRUE,
                      n.breaks =10)+
    ggtitle("Spring has sprung in many parts of the conterminous U.S.",
            subtitle = "Data: USA National Phenology Network. 2022. First Leaf - Spring Index. as of 04/03/2022 for conterminous U.S. USA-NPN, Tucson, Arizona, USA. http://dx.doi.org/10.5066/F7SN0723")+
    guides(fill = guide_colorsteps(
      direction = "horizontal",
      title.position = "top",
      label.theme = element_text(color = "white"),
      title.theme = element_text(color = "white"),
      barwidth = 15
    ))
  
  ggsave(file_out, width = 16, height = 9)
  return(file_out)
}
plot_spring_steps <- function(spring_timing, hist_timing, proj, file_out){
  # create stepped histogram
  # number of cells in each day
  anom_hist <- spring_timing %>% 
    group_by(timing_day) %>%
    summarize(n_cells = length(timing), area = sum(area)) %>%
    mutate(date = as.Date('2022-01-01')+timing_day-1) %>%
    ## adding rows on either end of timeseries to draw out steps
    add_row(timing_day = 6, n_cells = 0, area = 0, date = as.Date('2022-01-06'))%>%
    add_row(timing_day = 5, n_cells = 0, area = 0, date = as.Date('2022-01-05'))%>%
    add_row(timing_day = lubridate::yday(Sys.Date())+1, n_cells = 0, area = 0,date = as.Date('2022-01-01')+timing_day-1)
  
  hist_hist <- hist_timing %>% 
    group_by(timing_day) %>%
    summarize(n_cells = length(timing), area = sum(area)) %>%
    mutate(date = as.Date('2022-01-01')+timing_day-1) 

  anom_hist %>%
    ggplot() +
    geom_bar(stat='identity', aes(x = date, y = area, fill = timing_day), alpha = 0.2)+
    geom_step(aes(x = date, y = area, color = timing_day), 
              direction = 'mid',
              size = 1
    )+
    geom_step(data = hist_hist, 
              aes(x = date, y = area), 
              direction = 'mid',
              size = 1,
              color = "white"
    )+
    geom_tile(aes(x=date, y = -7000, height = 10000,fill = timing_day))+
    theme(
      plot.background = element_rect(fill = NA, color = NA),
      panel.background = element_rect(fill = NA, color = NA),
      axis.text = element_text(color = "white", size = 16),
      panel.grid = element_blank(),
      plot.title = element_text(color = "white", size = 30, face = "bold"),
      plot.subtitle = element_text(color = "white"),
      axis.line = element_blank(),
      legend.position = 'none',
      legend.background = element_blank(),
      legend.text = element_blank(),
      legend.title = element_blank(),
      axis.ticks = element_line(color="white"),
      axis.ticks.y=element_blank(),
      axis.text.y=element_blank())+
    scale_color_stepsn(colors = sequential_hcl(10, "TealGrn"),
                       "First leaf date",
                       na.value = NA,
                       show.limits = TRUE,
                       n.breaks = 10) +
    scale_fill_stepsn(colors = sequential_hcl(10, "TealGrn"),
                      "First leaf date",
                      na.value = NA,
                      show.limits = TRUE,
                      n.breaks = 10) +
    scale_x_continuous(
      breaks = seq.Date(as.Date('2022-01-04'), 
                        #Sys.Date(), 
                        max(na.omit(hist_hist$date)),
                        by = '1 week'),
      labels = scales::label_date_short())+
    scale_y_continuous(expand=c(0,0))+
    labs(x='', y='') 
  
  ggsave(file_out, width = 16, height = 4)
  return(file_out)
}