save_lc_img_gif<- function(raster_list, legend_df){

  raster_list <- p2_lc_rasters_reclassified[2:3]
  colorkey = color_key
  
  raster_list <- raster::stack(raster_list)
  # Make a list of years in string format for titles
    imgs <- for(i in c(1:nlayers(raster_list))){
        
        ## transform into categorical data
        rat_lc <- ratify(raster_list[[1]])
        
        ## produce levelplot
        a <-levelplot(rat_lc, att='ID', 
                     col.regions=legend_df$color,
                     par.settings = list(axis.line = list(col = "transparent"),
                                         strip.background = list(col = 'transparent'),
                                         strip.border = list(col = 'transparent')),
                     scales = list(col = "transparent"),
                     main=paste0("drb land cover ", names(raster_list[[1]])),
                     colorkey=F,
                     key = list(rectangles=list(col = legend_df$color), 
                                text=list(lab=legend_df$Reclassify_description),
                                space='left',
                                columns=1,
                                size=2,
                                cex=.6)
        )
        
        print(a)
      }
    
    saveGIF(imgs, 
           interval=0.8, movie.name="gif_test.gif", ani.width = 1000)
  
}

save_lc_img_gif(p2_lc_rasters_reclassified[2:3], legend_df = legend_df)
