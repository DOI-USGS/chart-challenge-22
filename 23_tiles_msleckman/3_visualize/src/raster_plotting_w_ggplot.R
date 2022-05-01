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
      range = c(0.3, 1),
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
                          chart_year){

  # Plot area through time
  plot_count_df <- counts %>% 
    transform(year = as.numeric(year)) %>%
    # filter to current year or earlier for bars to accumulate
    filter(year <= as.numeric(chart_year))
  
  # Order land cover categories for legend
  legend_df <- legend_df %>%
    transform(Reclassify_match = factor(Reclassify_match, 
                                        ordered = TRUE, 
                                        levels = levels(counts$lc_order))) %>%
    arrange(Reclassify_match)

 plot_count_df %>%
  ggplot(aes(as.character(year), 
             percent, 
             group = lc_order, 
             fill = lc_order)
  )+
  ## stacked bar plot
  geom_bar(stat = 'identity')+
   geom_text(aes(label = year, y = 0),
             angle = 90,
             color = "white", 
             hjust = -0.1,
             size = 6)+
  scale_fill_manual(
    values = legend_df$color_hex,
    labels = legend_df$Reclassify_description,
    "Land cover"
  ) +
  theme_classic(base_size = 18) +
   scale_y_continuous(
     breaks = c(0, 1),
     labels = scales::label_percent(accuracy = 1),
     expand = c(0,0)
   ) +
   scale_x_discrete(
     breaks = years,
     limits = years
   ) +
   #theme(legend.position = 'none') +
   labs(x = NULL, y = NULL)
  
}
compose_lc_frames <- function(lc_map_fp,
                              lc_chart,
                              frame_year,
                              font_fam = "Dongle",
                              out_folder, title,
                              legend_df){
  
  # import fonts
  font_legend <- 'Source Sans Pro'
  font_add_google(font_legend, regular.wt = 400, bold.wt = 700) 
  font_add_google(font_fam, regular.wt = 300, bold.wt = 700) 
  showtext_opts(dpi = 300)
  showtext_auto(enable = TRUE)

  # legend
  p_legend <- get_legend(lc_chart +
                           # reorder keys 
                           scale_fill_manual(
                             values = legend_df$color_hex,
                             labels = legend_df$Reclassify_description,
                             "Land cover"
                           )+
                           guides(fill=guide_legend(
                             title = '',
                             label.theme = element_text(family = font_legend, size = 18))))
  
  # logo
  usgs_logo <- magick::image_read('../logo/usgs_logo_white.png') %>%
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
    draw_image(lc_map,
              y = plot_margin, x = 0.5+plot_margin,
              height = 0.95, width = 0.5) +
    # draw area chart
    draw_plot(lc_chart + 
                theme(legend.position = "none",
                      text = element_text(family = font_legend, size = 18),
                      axis.text.y = element_text(family = font_legend, size = 18, color = 'black'),
                      axis.text.x = element_blank(),
                      axis.ticks.x = element_blank(),
                      axis.line.x = element_blank()),
              y = 0.1, x = plot_margin*2,
              height = 0.45, width = 0.5) +
    # draw legend
    draw_plot(p_legend,
              y = 0.875, x = plot_margin*2, 
              width = 0.5, height = 0.35,
              hjust = 0, vjust = 1,
              halign = 0, valign = 1) +
    # draw title
    draw_label(title,
               x = plot_margin, y = 1-plot_margin, 
               fontface = "bold", 
               size = 45, 
               hjust = 0, 
               vjust = 1,
               fontfamily = font_fam,
               lineheight = 1) +
    # add some explanation
    draw_label('100 Year timeseries based on backcasted data\nfrom X for years #-# and\nNLCD data from fedData for 2001, 2011, and 2019.',
               x = plot_margin*2, y = 0.9, 
               size = 18, 
               hjust = 0, 
               vjust = 1,
               fontfamily = font_legend,
               lineheight = 1.1) +
    # add author
    draw_label("Margaux Sleckman, USGS\nData: USGS National Land Cover Database", 
               x = 1-plot_margin, y = plot_margin, 
               fontface = "italic", 
               size = 14, 
               hjust = 1, vjust = 0,
               fontfamily = font_legend,
               lineheight = 1.1) +
    # add logo
    draw_image(usgs_logo, x = plot_margin, y = plot_margin, width = 0.15, hjust = 0, vjust = 0, halign = 0, valign = 0)
  
  ggsave(sprintf('%s/nlcd_frame_%s.png', out_folder, frame_year), height = 10, width = 10, device = 'png', dpi = 300)
  return(sprintf('%s/nlcd_frame_%s.png', out_folder, frame_year))
  
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
