read_in_reclassify <- function(lc_tif_path, reclassify_legend,
                               value_cols = c('FORESCE_value','Reclassify_match'),
                               legend_file_sep = ',', aoi_for_crop = NULL,
                               out_folder = '2_process/out/reclassified/'){
  
  #' @param lc_tif_path path to land cover tif file e.g. 'drb_backcasting_2010.tif'
  #' @param reclassify_legend 2 or 3 col dataframe/matrix or path to csv reclassification map. See raster::reclassify() documentation for param 'rcl'
  #' @param legend_file_sep if reclassify_legend is a path to csv, specify separation type. Default assume csv and sep = 
  #' 
  #' @example read_in_reclassify(lc_tif_file = '1_fetch/out/DRB_Historical_Reconstruction_1680-2010/drb_backcasting_2010.tif', reclassify_legend = legend_reclassify)
  
  #lc_tif_path <- p1_FORESCE_lc_tif_download_filtered[1] # to remove
  
  if(!is.null(aoi_for_crop)){
    raster <- raster(lc_tif_path) %>% mask(., aoi_for_crop)}
  else{raster <- raster(lc_tif_path)}

  ## Read in legend file - option if reclassify_legend is a file path or a df already
  if(is.data.frame(reclassify_legend)){
    reclassify_matrix <- reclassify_legend %>% dplyr::select(any_of(value_cols)) %>% as.matrix()
  } else if(is.character(reclassify_legend)){
    reclassify_matrix <- read.delim(reclassify_legend, sep = legend_file_sep) %>% dplyr::select(any_of(value_cols)) %>% as.matrix()
  } else {
    print('legend_reclassify_file must already be a dataframe or matrix, or a path to delimited table file')
  }
  
  ##  define name of output file
  name <- paste0('reclassified_', basename(lc_tif_path))
  
  ## Run Reclassify + save
  start_time <- Sys.time()
  print('Running reclassification')
  # reclassify documentation: https://www.rdocumentation.org/packages/raster/versions/3.5-15/topics/reclassify
  reclassified_raster <- raster::reclassify(raster, reclassify_matrix, filename = file.path(out_folder,name),format="GTiff", overwrite=TRUE)
  # reclassified_raster <- raster::reclassify(raster, reclassify_matrix)
  
  ## RM zero values 
  reclassified_raster[reclassified_raster == 0] <- NA
  
  end_time <- Sys.time()
  print(end_time - start_time)
  return(paste0(out_folder,name))
  #return(reclassified_raster)
  
  }

## OLD CODE
#mapview(raster) # to remove

#reclassify_legend <- reclassify_df # to remove
#value_cols = c('FORESCE_value','Reclassify_match') # to rm



# reclassify_nlcd(nlcd_tif_path = '1_fetch/out/nlcd/nlcd_2001.tif', reclassify_legend = reclassify_df_nlcd,
#                 value_cols = c('NLCD_value','Reclassify_match'), legend_file_sep = ',',
#                 aoi = drb_boundary, out_folder = '2_process/out/'){
#   
#   ## read in legend file
#   if(is.data.frame(reclassify_legend)){
#     reclassify_matrix <- reclassify_legend %>% dplyr::select(all_of(value_cols)) %>% as.matrix()
#   } else if(is.character(reclassify_legend)){
#     reclassify_matrix <- read.delim(reclassify_legend, sep = legend_file_sep) %>% dplyr::select(all_of(value_cols)) %>% as.matrix()
#   } else {
#     print('legend_reclassify_file must already be a dataframe or matrix, or a path to delimited table file')
#   }
#   
#   name <- paste0('reclassified_', basename(nlcd_tif_path))
#   
#   
# }
>>>>>>> d992a1c800d3c42b00c5b6da7e16e529d59a5353