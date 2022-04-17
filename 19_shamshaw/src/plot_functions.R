
horiz_swarm_plot <- function(swarm_data){
  
  # set breaks
  max_dur <- max(swarm_data$duration)
  max_rnum <- max(swarm_data$rnum)
  
  hbreaks <- BAMMtools::getJenksBreaks(swarm_data$duration, k=10)
  scaledBreaks <- scales::rescale(c(0,hbreaks), c(0,1))
  
  combined_swarms <- swarm_data %>%
    mutate(year = lubridate::year(date)) %>%
    mutate(date_order = as.numeric(date-as.Date('1980-01-01')))
  
  ## add first date for each year label positioning
  x_df <- combined_swarms %>% 
    distinct(year) %>% 
    mutate(date_start = as.Date(sprintf('%s-01-01', year))) %>% 
    mutate(date_order = as.numeric(date_start-as.Date('1980-01-01'))) 
  
  # add font
  font_fam <- 'Noto Sans Display'
  font_add_google(font_fam, regular.wt = 300, bold.wt = 700) 
  showtext_opts(dpi = 300)
  showtext_auto(enable = TRUE)
  
  # build plot
  p <- combined_swarms %>%
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
                     guide_legend(title = "Drought duration (days)"),
                     breaks = c(5, 100, 200, 300)) +
    theme_minimal(base_size = 16)+
    ylab(element_blank()) +
    xlab(element_blank()) +
    # custom x-axis labelling
    geom_text(data = x_df %>%
                filter(year %in% seq(1980, 2020, by = 5)),
              aes(x=-66, label = year),
              color = "black",
              size = 6,
              family = font_fam, fontface="bold") +
    # vertical gridlines for x axis
    geom_segment(data = x_df %>%
                   filter(year %in% seq(1980, 2020, by = 5)),
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
      title.position = "top",
      title.theme = element_text(vjust = 1, size = 16, family = font_fam)
    )) +
    coord_flip(clip = "off")
  
  
  # piece together plot elements
  p_legend <- get_legend(p) # the legned
  logo <- magick::image_read('../logo/usgs_logo_white.png') %>%
    magick::image_resize('x100') %>%
    magick::image_colorize(100, "black")

  ggdraw(xlim = c(0, 0.97), ylim = c(-0.05, 1)) +
    draw_plot(p+theme(legend.position = "none"), 
              y = 0, x = 0, 
              height = 1) +
    draw_label("40+ Years of Streamflow Drought\nin the Upper Colorado River Basin", 
               x = 0.015, y = 0.9, 
               fontface = "bold", 
               size = 30, 
               hjust = 0, 
               fontfamily = font_fam,
               lineheight = 1.1) +
    draw_label("Scott Hamshaw, USGS\nData: NWIS", 
               x = 0.95, y = -0.025, 
               fontface = "italic", 
               size = 14, 
               hjust = 1, vjust = 0,
               fontfamily = font_fam,
               lineheight = 1.1) +
    draw_plot(p_legend, x = 0.06, y = 0.73, width = 0.2, height = 0.1, hjust = 0) +
    draw_image(logo, x = 0.015, y = -0.025, width = 0.08, hjust = 0, vjust = 0, halign = 0, valign = 0)
  
  
}
event_swarm_plot <- function(swarm_data){
  
  max_dur <- max(swarm_data$duration)
  max_rnum <- max(swarm_data$rnum)
  
  hbreaks <- BAMMtools::getJenksBreaks(swarm_data$duration, k=10)
  scaledBreaks <- scales::rescale(c(0,hbreaks), c(0,1))
  
  # add font
  font_fam <- 'Noto Sans Display'
  font_add_google(font_fam, regular.wt = 300, bold.wt = 700) 
  showtext_opts(dpi = 300)
  showtext_auto(enable = TRUE)
  
  p <- swarm_data %>% ggplot()+
    geom_hline(yintercept=0, color="#dddddd",size = 1)+
    geom_tile(aes(x=date, y=rnum, fill = duration), height=0.5)+
    scale_fill_scico(values = scaledBreaks, palette = "lajolla", begin = 0.25, end = 1 , direction = 1,
                     guide_legend(title = "Drought Duration (Days)"), breaks = c(5, 100, 200, 300))+
    theme_minimal()+
    ylab(element_blank())+
    xlab(element_blank())+
    scale_x_date(breaks = scales::date_breaks(width = '1 month'),
                 labels = scales::label_date_short())+
    theme(axis.text.y=element_blank(),
          axis.text.x=element_text(size = 14, family = font_fam, hjust = 0),
          panel.grid = element_blank(),
          axis.line.x = element_line(color = "black"),
          legend.justification = "center",
          legend.direction = "horizontal",
          panel.spacing.y=unit(0, "lines"))+
    guides(fill = guide_colorbar(
      barheight = 0.62,
      barwidth = 21,
      title.position = "top",
      title.theme = element_text(vjust = 1, size = 16, family = font_fam),
      label.theme=element_text(family = font_fam)
    ))
  
  # piece together plot elements
  p_legend <- get_legend(p) # the legned
  logo <- magick::image_read('../logo/usgs_logo_white.png') %>%
    magick::image_resize('x100') %>%
    magick::image_colorize(100, "black")
  
  ggdraw(xlim = c(0, 1), ylim = c(0, 1)) +
    draw_plot(p+theme(legend.position = "none"), 
              y = 0.1, x = 0, 
              height = 0.8,
              width = 0.95) +
    draw_label("Streamflow Drought Duration\n2020 & 2021", 
               x = 0.015, y = 0.9, 
               fontface = "bold", 
               size = 30, 
               hjust = 0, 
               fontfamily = font_fam,
               lineheight = 1.1) +
    draw_label("Scott Hamshaw, USGS\nData: NWIS", 
               x = 0.95, y = 0.05, 
               fontface = "italic", 
               size = 14, 
               hjust = 1, vjust = 0,
               fontfamily = font_fam,
               lineheight = 1.1) +
    draw_plot(p_legend, x = 0.06, y = 0.73, width = 0.2, height = 0.1, hjust = 0) +
    draw_image(logo, x = 0.015, y = 0.05, width = 0.08, hjust = 0, vjust = 0, halign = 0, valign = 0)
  
}
