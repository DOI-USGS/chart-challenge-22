downsamp_cat <- function(raster_path, down_fact, out_folder){
  #' @param raster_path file path for input raster
  #' @param down_fact factor to downsample by in x and y direction

  raster <- terra::rast(raster_path) # convert to Spat
  year <- str_sub(names(raster), -4, -1)
                  
  # split into separate layers for each category
  rast_seg <- terra::segregate(raster)
  
  # Aggregate each layer to new resolution
  rast_down <- terra::aggregate(rast_seg, fact = down_fact,  sum) 
  
  # save as tif
  file_out <- sprintf('%s/drb_lc_downsampled_%s.tif', out_folder, year)
  terra::writeRaster(rast_down, filename = file_out, overwrite = TRUE)
  return(file_out)
}

resample_cat_raster <- function(raster, raster_grid, year, down_fact){

  # split into separate layers for each category
  rast_seg <- terra::segregate(raster)

  # resample each layer using lower dimension year
  rast_resamp <- terra::resample(rast_seg, raster_grid)
  rast_down <- terra::aggregate(rast_resamp, fact = down_fact,  sum) # downsample

  # create unique id for each grid cell
  rast_df <- terra::values(rast_down, dataframe = TRUE) %>%
    rowid_to_column('cell_id')
  
  # get rid of empties
  rast_complete <- rast_df[complete.cases(rast_df[,-1]),]
  rast_complete$year <- year
  return(rast_complete)
}