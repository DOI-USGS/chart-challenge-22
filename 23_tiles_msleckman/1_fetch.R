source('1_fetch/src/download_tifs_fun.R')
source('1_fetch/src/fetch_nlcd.R')

p1_targets_list <- list(
  
  ## Download all historical FORESCE data available for DRB for 1640  - 2010
  ## https://www.sciencebase.gov/catalog/item/605c987fd34ec5fa65eb6a74
  tar_target(
    p1_FORESCE_lc_tif_download,
    download_tifs(sb_id = '605c987fd34ec5fa65eb6a74',
              filename = 'DRB_Historical_Reconstruction_1680-2010.zip',
              download_path = '1_fetch/out',
              ## Subset downloaded tifs to only process the  years that are relevant model
              year = NULL,
              name_unzip_folder = NULL,
              overwrite_file = TRUE,
              name = NULL),
    format = 'file'),
  
  ## Subset FORESCE (FOR) historical land cover files to the years of interest
  tar_target(
    p1_FORESCE_lc_tif_download_filtered,
    p1_FORESCE_lc_tif_download %>% str_subset(
      ## we select years by filtering a regex pattern 
      pattern = '1900|1910|1920|1930|1940|1950|1960|1970|1980|1990')
    ),
  
  ## Get drb boundary shp 
  ## https://www.sciencebase.gov/catalog/item/5d94949de4b0c4f70d0db64f
  tar_target(
    p1_drb_boundary_zip,
    sbtools::item_file_download(sb_id = '5d94949de4b0c4f70d0db64f',
                                names = 'physiographic_regions_DRB.zip',
                                destinations = '1_fetch/out/physiographic_regions_DRB.zip',
                                overwrite_file = TRUE),
    format = 'file'
    ),
  
  tar_target(
    p1_drb_boundary_unzip,
    unzip(p1_drb_boundary_zip, exdir = '1_fetch/out/physiographic_regions_DRB', overwrite = TRUE),
    format = 'file'
  ),
  
  tar_target(
    p1_drb_boundary,
    st_read(p1_drb_boundary_unzip %>% str_subset('.shp$')) %>%
      # head(5) %>% 
      group_by(Source) %>%
      summarize() %>% 
      mutate(region = 'drb') 
      ## keeping the projection of this file
      ), 
  
  # use DRB boundary to get flowlines from NHD
  # using this method to be able to get straemorder for plotting
  tar_target(
    p1_drb_huc8,
    nhdplusTools::get_huc8(AOI = p1_drb_boundary)
    ),
  
  tar_target(
    p1_drb_flines,
    nhdplusTools::get_nhdplus(AOI = p1_drb_huc8, realization = 'flowline')
  ),
  
  tar_target(
    p1_streams_polylines_drb,
    p1_drb_flines %>%
      group_by(streamorde) %>%
      summarize() %>%
      rmapshaper::ms_simplify() %>%
      st_intersection(p1_drb_boundary)
  ),
  
  ## Get nlcd data using the FedData package and the get_nlcd() function 
  ## This process includes fetching + masking raster to aoi (drb aoi in our case) 
  tar_target(
    p1_fetch_nlcd_all_years, 
    {lapply(nlcd_years, function(x) 
      get_nlcd_aoi(aoi = p1_drb_boundary,
                   aoi_label = 'drb',
                   nlcd_dataset = 'landcover',
                   nlcd_year = x,
                   file_name = paste0('nlcd_', x, '.tif'),
                   out_folder = '1_fetch/out/nlcd'))
    })

)
