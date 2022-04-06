source('1_fetch/src/download_tifs_fun.R')


p1_targets_list <- list(
  
  ## download all FORESCE Data 1640 - 2010
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
    format = 'file')

)

#sbtools::item_file_download(sb_id = '5d4c6a1de4b01d82ce8dfd2f', dest_dir = '1_fetch/out/')