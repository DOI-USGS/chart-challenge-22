raster_ploting_w_ggplot <- function(raster_in, reach_shp, legend_df, out_folder = "3_visualize/out/"){
  
  #raster_in <- p2_reclassified_raster_list[[1]]
 # raster_name <- names(raster_in[1])
 # raster_in <- raster_in[[1]]
 # raster_in
 # #
 # raster_df <- as.data.frame(raster_in, xy = TRUE) %>%
 #   #na.omit() %>%
 #   rename(value = 3)#{{raster_name}})
 # 
 # raster_name <- names(raster_in)
 # frame_out <- paste0(out_folder, "ggplot_", raster_name,'.png')
 # png(frame_out)
 # 
  ggplot()+
    geom_raster(data = raster_in, 
                aes(x=x, y=y, fill = factor(name))) +
    geom_sf(data = reach_shp %>%
              filter(streamorde > 2), 
            color = "white", 
            aes(size = streamorde)) +
    theme_void() +
    theme(legend.position = "none")+
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
   
  ggsave(sprintf('%s/gg_%s.png', out_folder, unique(raster_in$rast)), height = 9, width = 6)
  ## legend to add. color for legend mapped out in legend_df
  
  
}


