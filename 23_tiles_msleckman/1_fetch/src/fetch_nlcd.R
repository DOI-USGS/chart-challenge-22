get_nlcd_aoi <- function(aoi, aoi_label = 'drb', nlcd_dataset = 'landcover',
                         nlcd_year, file_name, out_folder){
  
  print(nlcd_year)
  start_time <- Sys.time()
  # +proj=aea +lat_1=20 +lat_2=60 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs 
  ## this will give us the nlcd data for the extent of the aoi 
  raster_aoi <- get_nlcd(template = aoi, label = aoi_label, year = nlcd_year , dataset = nlcd_dataset) 
  
  ## CHECK THAT CRS IS SAME 
  #if(st_crs(aoi) == st_crs(raster_aoi)){print('crs are same for raster and the boundary')} else{print('crs different, fix')}
  
  ## crop first - not necessary - to confirm 
  #cropped_raster_aoi <- raster::crop(raster_aoi, aoi)
  
  ## mask 
  mask_raster_aoi <- raster::mask(raster_aoi, aoi)
  
  path <- file.path(out_folder, file_name)
  out_raster <- writeRaster(mask_raster_aoi, filename = path, format = 'GTiff', overwrite = TRUE)
  end_time <- Sys.time()
  print(end_time - start_time)
  
  return(path)
}
