raster_ploting_w_ggplot <- function(raster_in, reach_shp, out_folder = "3_visualize/out/"){
  
  raster_in <- p2_reclassified_raster_list[[1]]
  raster_df <- as.data.frame(raster_in, xy = TRUE) %>% na.omit()
  
  raster_name <- names(raster_in)
  frame_out <- paste0(out_folder, "ggplot_", raster_name,'.png')
  png(frame_out)
  
  raster_plot <- ggplot()+
    geom_raster(data = raster_df, aes(x = x, y = y, fill = raster_name))+
    geom_sf(data = reach_shp, color = 'blue')
  
  ## legend to add. color for legend mapped out in legend_df
  
    
  print(raster_plot)
  dev.off()
  
}


