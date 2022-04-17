multi_panel_swarm_plot <- function(...){
  
  combined_swarms <- bind_rows(...)
  
  max_dur <- max(combined_swarms$duration)
  max_rnum <- max(combined_swarms$rnum)
  
  hbreaks <- BAMMtools::getJenksBreaks(combined_swarms$duration, k=10)
  scaledBreaks <- scales::rescale(c(0,hbreaks), c(0,1))
  
  p <- combined_swarms %>% ggplot()+
    geom_hline(yintercept=0, color="#dddddd",size = 1)+
    geom_tile(aes(x=date, y=rnum, fill = duration), height=0.7)+
    scale_fill_scico(values = scaledBreaks, palette = "lajolla", begin = 0.25, end = 1 , 
                     direction = 1, guide_legend(title = "Drought Duration (Days)"),
                     breaks = c(5, 100, 200, 300))+
    theme_minimal()+
    ylab(element_blank())+
    xlab(element_blank())+
    theme(axis.text.y=element_blank(),
          panel.grid = element_blank(),
          axis.line.x = element_line(color = "black"),
          strip.text = element_blank(),
          panel.spacing.y=unit(0, "lines"),
          axis.ticks.x = (element_line(size=1)),
          legend.position = "left", 
          legend.justification = "bottom",
          legend.direction = "horizontal")+
    facet_col(vars(decade), scales = "free", space = "free")

  return(p) 
  
}
horiz_swarm_plot <- function(swarm_data){
  
  # set breaks
  max_dur <- max(swarm_data$duration)
  max_rnum <- max(swarm_data$rnum)
  
  hbreaks <- BAMMtools::getJenksBreaks(swarm_data$duration, k=10)
  scaledBreaks <- scales::rescale(c(0,hbreaks), c(0,1))
  
  combined_swarms <- swarm_data %>%
    mutate(year = lubridate::year(date)) %>%
    mutate(decade_order = as.numeric(date-as.Date(sprintf('%s-01-01', decade), '%Y-%d-%m')),
           date_order = as.numeric(date-as.Date('1980-01-01')))
  
  ## add first and last date for each decade
  x_df <- combined_swarms %>%
    distinct(year) %>% 
    mutate(decade = as.factor(floor(year/10)*10),
           date_start = as.Date(sprintf('%s-01-01', year)),
           date_end = as.Date(sprintf('%s-12-31', year))) %>% 
    pivot_longer(!c(decade, year), values_to = 'date') %>% 
    mutate(rnum = NA, names = NA, duration = NA, dt = NA) %>%
    mutate(decade_order = as.numeric(date-as.Date(sprintf('%s-01-01', decade), '%Y-%d-%m')),
           date_order = as.numeric(date-as.Date('1980-01-01'))) %>%
    select(names(combined_swarms)) 
 
  
  # add empty rows to data
  plot_df <- combined_swarms %>%
    bind_rows(x_df) 
  
  # add font
  font_fam <- 'Noto Sans Display'
  font_add_google(font_fam, regular.wt = 300, bold.wt = 700) 
  showtext_opts(dpi = 300)
  showtext_auto(enable = TRUE)
  
  # build plot
  p <- plot_df %>%
    ggplot(aes(y = date_order, x = rnum))+
    geom_vline(xintercept = 0, color="#dddddd",size = 1)+
    geom_tile(aes(fill = duration), 
              width = 0.75
    )+
    scale_fill_scico(values = scaledBreaks, 
                     palette = "lajolla", 
                     begin = 0.25, 
                     end = 1 , 
                     direction = 1, 
                     guide_legend(title = "Duration (days)"),
                     breaks = c(5, 100, 200, 300)) +
    theme_minimal(base_size = 16)+
    ylab(element_blank()) +
    xlab(element_blank()) +
    # custom x-axis labelling
    geom_text(data = x_df %>%
                filter(year %in% seq(1980, 2020, by = 5)) %>%
                group_by(decade, year)%>%
                slice_min(date_order),
              aes(x=-66, label = year),
              color = "black",
              family = font_fam) +
    # vertical gridlines for x axis
    geom_segment(data = x_df %>%
                   filter(year %in% seq(1980, 2020, by = 5)) %>%
                   group_by(decade, year)%>%
                   slice_min(date_order),
                 aes(x=-64, xend = -2, yend=date_order),
                 color = "grey",
                 linetype = "dotted")+
    theme(text = element_text(family = font_fam),
          axis.text=element_blank(),
          panel.grid = element_blank(),
          axis.line = element_blank(),
          axis.ticks = element_blank(),
          legend.box.just = "left",
          legend.direction = "horizontal") +
    guides(fill = guide_colorbar(
      barheight = 0.62,
      barwidth = 21,
      
      title.theme = element_text(vjust = 1, size = 16, family = font_fam)
    )) +
    coord_flip(clip = "off")
  
  
  # piece together plot elements
  p_legend <- get_legend(p)

  ggdraw() +
    draw_plot(p+theme(legend.position = "none")) +
    draw_label("40 Years of Streamflow Drought\nin the Upper Colorado River Basin", x = 0.015, y = 0.9, 
               fontface = "bold", size = 30, hjust = 0, fontfamily = font_fam,
               lineheight = 1.1) +
    draw_plot(p_legend, x = 0.13, y = 0.75, width = 0.2, height = 0.1)
  
  
}
event_swarm_plot <- function(swarm_data){
  
  max_dur <- max(swarm_data$duration)
  max_rnum <- max(swarm_data$rnum)
  
  hbreaks <- BAMMtools::getJenksBreaks(swarm_data$duration, k=10)
  scaledBreaks <- scales::rescale(c(0,hbreaks), c(0,1))
  
  p <- swarm_data %>% ggplot()+
    geom_hline(yintercept=0, color="#dddddd",size = 1)+
    geom_tile(aes(x=date, y=rnum, fill = duration), height=0.5)+
    scale_fill_scico(values = scaledBreaks, palette = "lajolla", begin = 0.25, end = 1 , direction = 1,
                     guide_legend(title = "Drought Duration (Days)"), breaks = c(5, 100, 200, 300))+
    theme_minimal()+
    ylab(element_blank())+
    xlab(element_blank())+
    theme(axis.text.y=element_blank(),
          panel.grid = element_blank(),
          axis.line.x = element_line(color = "black"),
          strip.text = element_blank(),
          legend.position = "bottom", 
          legend.justification = "center",
          legend.direction = "horizontal",
          panel.spacing.y=unit(0, "lines"))
  
  return(p) 
  
}