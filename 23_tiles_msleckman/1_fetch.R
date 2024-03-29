source('1_fetch/src/download_tifs_fun.R')
source('1_fetch/src/fetch_nlcd.R')

p1_targets_list <- list(
  
  ## Get drb boundary shp, unzip and aggregate to region
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
      group_by(Source) %>%
      summarize() %>% 
      mutate(region = 'drb') #%>%
      #st_transform('+proj=aea +lat_1=39.9 +lat_2=41.2 +lat_0=40.6 +lon_0=-75.5 +x_0=0 +y_0=0 +ellps=GRS80 +units=m +no_defs')
  ), 
  tar_target(
    p1_drb_extent,
    spData::us_states %>%
      sf::st_crop(c(xmin=-80, xmax=-65, ymin=47, ymax=33)) %>%
      st_transform(st_crs(p1_drb_boundary))
  ),
  
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
  ## Current and future FORSCEE data - Business as usual scenarios avg of RCP .5 and 8.5 (mid-high IPCC scenario)
  ## years 2020-2100 available
  tar_target(
    p1_FORESCE_current_lc_tif_download,
    download_tifs(sb_id = '605c987fd34ec5fa65eb6a74',
                  filename = 'DRB_BAU_RCPAvg_2020-2100.zip',
                  download_path = '1_fetch/out/BAU',
                  ## Subset downloaded tifs to only process the  years that are relevant model
                  year = NULL,
                  name_unzip_folder = NULL,
                  overwrite_file = TRUE,
                  name = NULL),
    format = 'file'),
  ## ALL FORESCE data
  tar_target(
    p1_FORESCE_lc_tif,
    c(p1_FORESCE_lc_tif_download, p1_FORESCE_current_lc_tif_download)
  ),
  tar_target(
    ## FOORESCE years for gif from past to current
    p1_FORESCE_years,
    c('1900','1910','1920','1930','1940','1950','1960','1970','1980','1990','2000','2010','2020')
  ),
  ## Subset FORESCE (FOR) historical land cover files to the years of interest
  tar_target(
    p1_FORESCE_lc_tif_download_filtered,
    ## select years by filtering a regex pattern 
    p1_FORESCE_lc_tif %>%
      str_subset(pattern = paste(sprintf('_%s.tif', p1_FORESCE_years), collapse='|'))
  ),
  
  ## Get more recent nlcd data using the FedData package and the get_nlcd() function 
  ## This process includes fetching + masking raster to aoi (drb aoi in our case) 
  tar_target(
    nlcd_years,
    list('2001', '2011', '2019')
  ),
  tar_target(
    p1_fetch_nlcd_all_years, 
    get_nlcd_aoi(aoi = p1_drb_boundary,
                 aoi_label = 'drb',
                 nlcd_dataset = 'landcover',
                 nlcd_year = nlcd_years,
                 file_name = paste0('nlcd_', nlcd_years, '.tif'),
                 out_folder = '1_fetch/out/nlcd'),
    pattern = map(nlcd_years),
    format = 'file'
  ),
  
  # use DRB boundary to get flowlines from NHD
  # NHD has streamorder for mapping stream width to later on
  tar_target(
    p1_drb_flines,
    get_nhdplus(AOI = p1_drb_boundary, realization = 'flowline')
  )

)
