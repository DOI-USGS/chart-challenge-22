rbind.fill.list <- function(x, fill = NULL) {
  
  #' @description Function that is variation to plyr::rbind.fill(), rbinds a list of tables and fill missing cols with NA. Taken from: https://stackoverflow.com/questions/17308551/do-callrbind-list-for-uneven-number-of-column
  #' @param x list of lists tables
  #' @param fill Default NULL. 
  
  # loop through element tables in list and extracts cols 
  colnames <- sapply(x, names)
  # get all unique colnames as a unique list 
  unique_colnames <- unique(unlist(colnames))
  # Extract length of all table list elements in input list x and apply to empty list with correct length
  len <- sapply(x, length)
  output_list <- vector("list", length(len))
  # Create output list of lists where all  values are position in correct col
  for (i in seq_along(len)) {
    output_list[[i]] <- unname(x[[i]])[match(unique_colnames, colnames[[i]])]
  }
  # rbind to dataframe
  df <- setNames(as.data.frame(do.call(rbind, output_list), stringsAsFactors=FALSE), unique_colnames) 
  
  # Option fill of missing values with given fill value if not NULL
  if(!is.null(fill)){
    df <- replace(df, is.na(df), fill)
  }
  return(df)
}

raster_to_catchment_polygons <- function(polygon_sf, raster,
                                         categorical_raster = NULL,
                                         raster_summary_fun = NULL,
                                         new_cols_prefix = NULL,
                                         fill = NULL, ...){
  
  #' @description Function extracts raster pixel per catchment polygon and calculated proportion of raster class per total
  #'
  #' @param polygon_sf sf object of polygon(s) in aoi
  #' @param raster path to '.tif' file or raster object or SpatRaster object  
  #' @param categorical_raster logical. If categorical raster, TRUE
  #' @param raster_summary_fun for continuous raster, function to summarize the data by geometry. kept NULL if categorical_raster = TRUE
  #' @param new_raster_prefix prefix added to colnames to label raster classes/values
  #' @value A dataframe with the same columns as the polygon_sf spatial dataframe (except geometry col) with additional columns of the Land Cover classes
  #' @example land cover raster ex: raster_to_catchment_polygons(polygon_sf = p1_catchments_edited_sf, raster = p1_FORESCE_backcasted_LC, categorical_raster = TRUE, new_cols_prefix = 'lc_)
  #' @example cont. raster ex: raster_to_catchment_polygons(polygon_sf = p1_catchments_edited_sf, raster = p1_rod_salt, categorical_raster = FALSE, raster_summary_fun = sum, new_cols_prefix = 'cont_raster')
  
  # read in 
  raster <- rast(raster)
  vector_sf <- polygon_sf 
  
  ## check vector geometries 
  if(any(!st_is_valid(vector_sf))){
    vector_sf <- st_make_valid(vector_sf)
    message('shp geometries fixed')
  } 
  
  ## match crs
  if(!st_crs(raster) == st_crs(vector_sf)){
    message('crs are different. Transforming ...')
    vector_sf <- st_transform(vector_sf, crs = st_crs(raster))
    if(st_crs(raster) == st_crs(vector_sf)){
      message('crs now aligned')}
  }else{
    message('crs are already aligned')
  }
  
  ## Convert vector sf object to Spatvector compatible to with raster processing with terra
  vector <- vector_sf %>% vect()
  
  ## crop raster to catchment_sf 
  raster_crop <- terra::crop(raster, vector)
  
  ## Extract and summarize discrete raster values in polygons shapefile 
  if(categorical_raster == TRUE){
    message('extracting from categorical raster')
    ## Extract rasters pixels in each polygon
    #start_time <- Sys.time()
    raster_per_polygon <- terra::extract(raster_crop, vector, list = TRUE) %>% 
      #lapply(table) # to get frequency of each categorical value
      lapply(FUN = function(x) {table(x)/sum(table(x))})
    #end_time <- Sys.time()
    #message('raster extract processing time:', end_time - start_time)
    
    ## handling unequal length of classes - filling missing values with given fill argument
    final_raster_table <- rbind.fill.list(raster_per_polygon, fill = fill) %>%
      setNames(paste0(new_cols_prefix, names(.))) %>% 
      mutate(ID = row_number())
    
  }
  
  ## Extract and summarize non-discrete raster values in polygons shapefile  
  else{
    message('extracting continuous raster')
    raster_per_polygon <- terra::extract(raster_crop, vector, fun = raster_summary_fun, ...)
    final_raster_table <- data.frame(raster_per_polygon)
    col_len <- length(names(final_raster_table))
    names(final_raster_table)[col_len] <- paste0(new_cols_prefix, names(final_raster_table)[col_len])
  }
  
  vector_sf <- vector_sf %>% st_drop_geometry() %>% mutate(ID = row_number())
  
  df <- left_join(x = vector_sf, y = final_raster_table , by = 'ID')
  
  return(df)
  
}
