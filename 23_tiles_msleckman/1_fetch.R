source('1_fetch/src/download_tifs_fun.R')

p1_targets_list <- list(
  
  ## Download all FORESCE Data 1640 - 2010
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
  
  ## Download all FORESCE Data 1640 - 2010
  tar_target(
    p1_FORESCE_lc_tif_download_filtered,
    p1_FORESCE_lc_tif_download %>% str_subset(pattern = '1900|1910|1920|1930|1940|1950|1960|1970|1980|1990|2000')
    )
)