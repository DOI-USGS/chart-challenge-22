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