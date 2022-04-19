produce_lc_img <- function(raster_in, raster_frame, legend_df, out_folder = "3_visualize/out/", reach_shp = NULL){
  
  # raster_in <- gif_frames$raster
  # raster_frame <- gif_frames$seq[3]

  raster_in <- raster_in[[raster_frame]]

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

## from https://github.com/USGS-VIZLAB/lake-temp-timeseries/blob/77d06c4e2f21b36b7e8619c84108f0a842d03e30/src/plot_utils.R#L101-L109
animate_frames_gif <- function(frames, out_file, reduce = TRUE, frame_delay_cs, frame_rate){
  frames %>%
    image_read() %>%
    image_join() %>%
    image_animate(
      delay = frame_delay_cs,
      optimize = TRUE,
      fps = frame_rate
    ) %>%
    image_write(out_file)
  
  if(reduce == TRUE){
    optimize_gif(out_file, frame_delay_cs)
  }
  
  return(out_file)
}

optimize_gif <- function(out_file, frame_delay_cs) {
  # simplify the gif with gifsicle - cuts size by about 2/3
  gifsicle_command <- sprintf('gifsicle -b -O3 -d %s --colors 256 %s', frame_delay_cs, out_file)
  system(gifsicle_command)
  
  return(out_file)
}