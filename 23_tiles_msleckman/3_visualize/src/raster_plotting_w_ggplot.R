raster_ploting_w_ggplot <- function(raster_in, reach_shp, counts, legend_df, title, font_fam = "Source Sans Pro", out_folder = "3_visualize/out/"){
  
  font_legend <- 'Source Sans Pro'
  
  nlcd_map <- ggplot()+
    geom_raster(data = raster_in, 
                aes(x=x, y=y, fill = factor(name))) +
    geom_sf(data = reach_shp %>%
              filter(streamorde > 2), 
            color = "white", 
            aes(size = streamorde)) +
    theme_void() +
    theme(
      #legend.position = "none",
      text = element_text(family = font_legend),
      panel.background = element_rect(fill = "white", color = NA),
      plot.background = element_rect(fill = "white", color = NA)
    )+
    scale_size(
      breaks = c(5, 6, 7),
      range = c(0.2, 0.8),
      guide = "none"
    ) +
    scale_fill_manual(
      values = legend_df$color,
      labels = legend_df$Reclassify_description,
      "Land cover"
    ) +
    coord_sf()
  
  
  # area through time
  nlcd_area <- counts %>% 
    # find % of total area in each category over time
    left_join(counts %>% 
                group_by(rast)%>%
                summarize(total_cells = sum(count))) %>%
    mutate(year = as.numeric(stringr::word(rast, 4, 4, sep ='_')),
           percent = count/total_cells) %>%
    filter(value != 0) %>% 
    ggplot(aes(year, 
               percent, 
               group = value, 
               color = factor(value), 
               fill = factor(value))
           ) +
    geom_line(size = 3, alpha = 0.7) +
    geom_point(size = 2, shape = 21, fill = "white", stroke = 1) +
    theme_classic(base_size = 16)+
    scale_y_continuous(
      labels = scales::label_percent(accuracy = 1),
      expand = c(0,0)
    )+
    scale_x_continuous(
      expand = c(0,0)
    ) +
    labs(x="", y="") +
    theme(
      text = element_text(family = font_legend)
      #legend.position = 'none',
      #plot.background = element_blank(),
      #panel.background = element_blank(),
    )+
    scale_color_manual(
      values = legend_df$color,
      labels = legend_df$Reclassify_description,
      "Land cover"
    )+
    scale_fill_manual(
      values = legend_df$color,
      labels = legend_df$Reclassify_description,
      "Land cover"
    )
  
  
  ##compose final plot
  file_name <- stringr::word(unique(raster_in$rast), 4, 4, sep = '_')
  
  # legend
  p_legend <- get_legend(nlcd_map)
  
  # logo
  usgs_logo <- magick::image_read('../logo/usgs_logo_white.png') %>%
    magick::image_resize('x100') %>%
    magick::image_colorize(100, "black")
  
  # add font
  font_add_google(font_fam, regular.wt = 300, bold.wt = 700) 
  showtext_opts(dpi = 300)
  showtext_auto(enable = TRUE)
  plot_margin <- 0.025
  
  # combine plot elements
  ggdraw(ylim = c(0,1), xlim = c(0,1)) +
    draw_plot(nlcd_map + theme(legend.position = "none"),
              y = 0.1, x = 0.3-plot_margin,
              height = 0.8, width = 0.35) +
    draw_plot(nlcd_area + theme(legend.position = "none"),
              y = 0.1, x = 0.65-plot_margin,
              height = 0.8, width = 0.35) +
    draw_plot(p_legend,
              y = 0.8, x = 0, 
              width = 0.3, height = 0.5,
              hjust = 0, vjust = 1,
              halign = 0, valign = 1) +
    draw_label(title, 
               x = plot_margin, y = 1-plot_margin, 
               fontface = "bold", 
               size = 40, 
               hjust = 0, 
               vjust = 1,
               fontfamily = font_fam,
               lineheight = 1.1) +
    draw_label("Margaux Sleckman, USGS\nData: NLCD", 
               x = 1-plot_margin, y = plot_margin, 
               fontface = "italic", 
               size = 14, 
               hjust = 1, vjust = 0,
               fontfamily = font_legend,
               lineheight = 1.1) +
    draw_image(usgs_logo, x = plot_margin, y = plot_margin, width = 0.1, hjust = 0, vjust = 0, halign = 0, valign = 0)
  
  ggsave(sprintf('%s/nlcd_%s.png', out_folder, file_name), height = 9, width = 14)
}
