downsamp_cat <- function(raster, down_fact){
  #' @param raster input raster
  #' @param down_fact factor to downsample by in x and y direction
  
  rast <- terra::rast(raster[[1]]) # convert to Spat
  rast_seg <- terra::segregate(rast) # split categorical data
  rast_down <- terra::aggregate(rast_seg, fact = down_fact,  sum) # downsample
  
  # convert to dataframe to plot wtih ggplot
  ## find the mode for each aggregated cell
  rast_down_df <- as.data.frame(rast_down, xy = TRUE) %>%
    pivot_longer(!c(x,y)) %>%
    filter(value > 0, name != 0) %>%
    group_by(x,y) %>%
    arrange(desc(value)) %>%
    slice_max(value, n=1)
  return(rast_down_df)
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