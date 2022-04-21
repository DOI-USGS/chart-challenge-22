produce_lc_levelplot <- function(raster_in, raster_frame, legend_df, out_folder = "3_visualize/out/", reach_shp = NULL){
  
  #  raster_in <- gif_frames$raster[3]
  # raster_frame <- gif_frames$seq[3]
  
  raster_in <- raster_in[[1]]
  
  ## transform into categorical raster
  rat_lc <- ratify(raster_in)
  
  # Produce levelplot
  ## define specs
  raster_name <- names(rat_lc)
  year <- substr(raster_name, nchar(raster_name)-3, nchar(raster_name))
  main_title <- paste0("drb land cover ",year)
  
  ## Plot
  frame_out <- paste0(out_folder, "Plot_", raster_name,'.png')
  png(frame_out)
  
  a <- levelplot(rat_lc, att='ID', 
                 col.regions=legend_df$color_hex,
                 par.settings = list(axis.line = list(col = "transparent"),
                                     strip.background = list(col = 'transparent'),
                                     strip.border = list(col = 'transparent')),
                 scales = list(col = "transparent"),
                 main= main_title,
                 colorkey=F,
                 key = list(rectangles=list(col = legend_df$color_hex), 
                            text=list(lab=legend_df$Reclassify_description),
                            space='left',
                            columns=1,
                            size=2,
                            cex=.6))
  
  if(!is.null(reach_shp)){
    a + layer(sp.polygons(reach_shp, lwd=0.8, col='blue'))
  }
  
  print(a)
  dev.off()
  return(frame_out)
  
}
