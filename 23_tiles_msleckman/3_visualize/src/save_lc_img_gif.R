produce_lc_img <- function(raster_list, legend_df, out_folder = "3_visualize/out/"){
  
  
  #stack to be able to produce level_plot 
  raster_list_stacked <- raster::stack(raster_list)
  
    for(i in c(1:nlayers(raster_list_stacked))){
        
        print(raster_list_stacked[[i]])
        ## transform into categorical raster
        rat_lc <- ratify(raster_list_stacked[[i]])
        
        # Produce levelplot
        ## define specs
        raster_name <- names(raster_list_stacked[[i]])
        year <- substr(raster_name, nchar(raster_name)-3, nchar(raster_name))
        main_title <- paste0("drb land cover ",year)
        
        ## Plot
        png(paste0(out_folder, "Plot_", raster_name,'.png'))
        
        a <-lattice::levelplot(rat_lc, att='ID', 
                     col.regions=legend_df$color,
                     par.settings = list(axis.line = list(col = "transparent"),
                                         strip.background = list(col = 'transparent'),
                                         strip.border = list(col = 'transparent')),
                     scales = list(col = "transparent"),
                     main= main_title,
                     colorkey=F,
                     key = list(rectangles=list(col = legend_df$color), 
                                text=list(lab=legend_df$Reclassify_description),
                                space='left',
                                columns=1,
                                size=2,
                                cex=.6))
        
        print(a)
        dev.off()
    }
  
  # list frames
  list_pngs <- list.files(paste0(out_folder,'Plot_reclassified'))
                          
  return(list_pngs)
  
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
