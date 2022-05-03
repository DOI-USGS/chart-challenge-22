read_in_reclassify <- function(lc_tif_path,
                               reclassify_legend,
                               value_cols = c('FORESCE_value','Reclassify_match'),
                               aoi_for_crop,
                               legend_file_sep = ',', 
                               out_folder = '2_process/out/reclassified/'){
  
  #' @param lc_tif_path path to land cover raster
  #' @param reclassify_legend 2 or 3 col dataframe/matrix or path to csv reclassification map. See raster::reclassify() documentation for param 'rcl'
  #' @param legend_file_sep if reclassify_legend is a path to csv, specify separation type. Default assume csv and sep = 
  #' 
  #' @example read_in_reclassify(lc_tif_path = p2_rasters_FOR_crop, reclassify_legend = legend_reclassify)
  
  raster <- crop(raster(lc_tif_path), aoi_for_crop)
  
  ## RM zero values 
  print(paste('old min:', raster@data@min))
  raster[raster == 0] <- NA
  print(paste('new min:',raster@data@min))

  ## Read in legend file - option if reclassify_legend is a file path or a df already
  if(is.data.frame(reclassify_legend)){
    reclassify_matrix <- reclassify_legend %>% 
      dplyr::select(any_of(value_cols)) %>% 
      as.matrix()
  } else if(is.character(reclassify_legend)){
    reclassify_matrix <- read.delim(reclassify_legend, sep = legend_file_sep) %>% 
      dplyr::select(any_of(value_cols)) %>% 
      as.matrix()
  } else {
    print('legend_reclassify_file must already be a dataframe or matrix, or a path to delimited table file')
  }
  
  ##  define name of output file
  name <- paste0('reclassified_', basename(lc_tif_path))
  
  ## Run Reclassify + save
  start_time <- Sys.time()
  print('Running reclassification')
  # reclassify documentation: https://www.rdocumentation.org/packages/raster/versions/3.5-15/topics/reclassify
  reclassified_raster <- raster::reclassify(raster, reclassify_matrix, filename = file.path(out_folder, name), format = "GTiff", overwrite = TRUE)

  end_time <- Sys.time()
  print(end_time - start_time)
  return(paste0(out_folder,name))
  

}


