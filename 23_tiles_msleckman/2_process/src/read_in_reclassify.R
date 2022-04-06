read_in_reclassify <- function(lc_tif_path, reclassify_legend, value_cols = c('FORESCE_value','Reclassify_match'), legend_file_sep = ','){
  
  #' @param lc_tif_path path to land cover tif file e.g. 'drb_backcasting_2010.tif'
  #' @param reclassify_legend 2 or 3 col dataframe/matrix or path to csv reclassification map. See raster::reclassify() documentation for param 'rcl'
  #' @param legend_file_sep if reclassify_legend is a path to csv, specify separation type. Default assume csv and sep = 
  #' 
  #' @example read_in_reclassify(lc_tif_file = '1_fetch/out/DRB_Historical_Reconstruction_1680-2010/drb_backcasting_2010.tif', reclassify_legend = legend_reclassify)
  
  raster <- raster(lc_tif_path)
  
  ## read in legend file
  if(is.data.frame(reclassify_legend)){
    reclassify_matrix <- reclassify_legend %>% dplyr::select(all_of(value_cols)) %>% as.matrix()
  } else if(is.character(reclassify_legend)){
    reclassify_matrix <- read.delim(reclassify_legend, sep = legend_file_sep) %>% dplyr::select(all_of(value_cols)) %>% as.matrix()
  } else {
    print('legend_reclassify_file must already be a dataframe or matrix, or a path to delimited table file')
  }
  
  ## reclassify
  reclassified_raster <- raster::reclassify(raster, reclassify_matrix)
  
  # ## CHange 0 raster values to NA
  # reclassified_raster[reclassified_raster == 0] <- NA

  
  return(reclassified_raster)
}
