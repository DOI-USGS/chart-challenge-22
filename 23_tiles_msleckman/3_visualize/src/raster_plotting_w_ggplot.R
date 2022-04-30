plot_raster_map <- function(year,
                            raster_df,
                            reach_shp,
                            extent_map,
                            legend_df,
                            out_folder = '3_visualize/out/map/'){
  
  ggplot()+
   # geom_sf(data = extent_map,
   #         fill = NA,
   #         color = "lightgrey") +
    geom_raster(data = raster_df, 
                aes(x=x, y=y, fill = factor(lc))) +
    geom_sf(data = reach_shp , 
            color = "white", 
            aes(size = streamorde)) +
    theme_void() +
    theme(legend.position = 'none') +
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
  
  ggsave(sprintf('%s/nlcd_map_%s.png', out_folder, year), height = 9, width = 5, device = 'png', dpi = 300)
}
plot_lc_chart <- function(counts,
                          legend_df,
                          years, 
                          chart_year,
                          out_folder){
  chart_year = 1910
  # Area through time
  counts %>% filter(year %in% c('1900','1910')) %>%
    # find % of total area in each category over time
    left_join(counts %>% 
                group_by(year)%>%
                summarize(total_cells = sum(count))) %>%
    mutate(percent = count/total_cells) %>%
    transform(year = as.numeric(year)) %>%
    # filter to current year or earlier for bars to accumulate
    filter(value != 0, year <= chart_year) %>%
    ggplot(aes(year, 
               percent, 
               group = value, 
               fill = factor(value))
    )+
    ## stacked bar plot
    geom_bar(stat = 'identity')+
    scale_fill_manual(
      values = legend_df$color,
      labels = legend_df$Reclassify_description,
      "Land cover type"
    ) +
    theme_classic()+
    scale_y_continuous(
      labels = scales::label_percent(accuracy = 1),
      expand = c(0,0)
    ) +
    scale_x_continuous(
      breaks = as.numeric(years),
      limits = c(NA, max(as.numeric(years))),
      expand = c(0,0)
    ) +
    theme(legend.position = 'none') +
    labs(x = NULL, y = NULL)
  
  ggsave(sprintf('%s/nlcd_chart_%s.png', out_folder, year), height = 9, width = 8, device = 'png', dpi = 300)
}
compose_lc_frames <- function(lc_map_fp,
                              lc_chart,
                              frame_year,
                              font_fam = "Dongle"){
  
  # import fonts
  font_legend <- 'Source Sans Pro'
  font_add_google(font_legend, regular.wt = 300, bold.wt = 700) 
  font_add_google(font_fam, regular.wt = 300, bold.wt = 700) 
  showtext_opts(dpi = 300)
  showtext_auto(enable = TRUE)

  # legend
  p_legend <- get_legend(lc_chart)
  
  # logo
  usgs_logo <- magick::image_read('../logo/usgs_logo_white.png') %>%
    magick::image_resize('x100') %>%
    magick::image_colorize(100, "black")
  
  plot_margin <- 0.025
  
  # background
  canvas <- grid::rectGrob(
    x = 0, y = 0, 
    width = 16, height = 9,
    gp = grid::gpar(fill = "white", alpha = 1, col = 'white')
  )
  
  # map
  lc_map <- magick::image_read(lc_map_fp)
  
  # combine plot elements
  ggdraw(ylim = c(0,1), xlim = c(0,1)) +
    # a white background
    draw_grob(canvas,
              x = 0, y = 1,
              height = 9, width = 16,
              hjust = 0, vjust = 1) +
    # draw map
    draw_image(lc_map ,
              y = 0.1, x = 0.3-plot_margin,
              height = 0.8, width = 0.35) +
    # draw area chart
    draw_plot(nlcd_area + theme(legend.position = "none"),
              y = 0.1, x = 0.65-plot_margin,
              height = 0.8, width = 0.35) +
    # draw legend
    draw_plot(p_legend,
              y = 0.8, x = 0, 
              width = 0.3, height = 0.5,
              hjust = 0, vjust = 1,
              halign = 0, valign = 1) +
    # draw title
    draw_label(title,
               x = plot_margin, y = 1-plot_margin, 
               fontface = "bold", 
               size = 40, 
               hjust = 0, 
               vjust = 1,
               fontfamily = font_fam,
               lineheight = 1.1) +
    # add author
    draw_label("Margaux Sleckman, USGS\nData: NLCD", 
               x = 1-plot_margin, y = plot_margin, 
               fontface = "italic", 
               size = 14, 
               hjust = 1, vjust = 0,
               fontfamily = font_legend,
               lineheight = 1.1) +
    # add logo
    draw_image(usgs_logo, x = plot_margin, y = plot_margin, width = 0.1, hjust = 0, vjust = 0, halign = 0, valign = 0)
  
  ggsave(sprintf('%s/nlcd_frame_%s.png', out_folder, chart_year), height = 1200, width = 675, device = 'png', dpi = 300)
  
}

plot_sankey <- function(){
  ggplot(p2_df, aes(
    x = x,
    next_x = next_x, 
    node = node,
    next_node = next_node,
    fill = factor(node)
  ))  +
    theme_sankey(base_size = 18)+
    geom_sankey(
      flow.alpha = 0.6,
      node.color = "white"
    )+
    scale_fill_manual(
      values = legend_df$color,
      labels = legend_df$Reclassify_description,
      "Land cover"
    )+
    labs(x='')  
}
