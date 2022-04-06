download_tifs <- function(sb_id, filename, download_path, overwrite_file = TRUE,
                          year = NULL, name_unzip_folder = NULL, name = NULL){
  
  #' @description Download and unzip specified file from sciencebase
  #' @param sb_id str. Sciencebase id. accepts a single str.
  #' @param filename str. Name of specific file to download from given sciencebase id. Accepts a single str.
  #' @param download_path str.Directory location of download
  #' @param overwrite_file binary T/F. Whether to re-download if specific downloaded file exists in directory. Default True
  #' @param year str or vector. years of interest. See sb metadata to know which years are of available
  #' @param name_unzip_folder name of subfolder for downloaded tif files. If NULL, name of zip file used as folder name
  #' @param name list of labels for list. default NULL.
  #' @example download_tifs(sb_id = '605c987fd34ec5fa65eb6a74', filename = 'DRB_Historical_Reconstruction_1680-2010.zip', download_path = '1_fetch/out', overwrite_file = T, year = c('2000','1990','1980','1970','1960'))
  #' @example download_tifs('5b15a50ce4b092d9651e22b9', filename = '1992_2015.zip', download_path = '1_fetch/out', overwrite_file = T, name_unzip_folder = 'rd_salt')
  
  path_to_downloaded_file <- file.path(download_path, filename)
  
  # Download specified file from sciencebase to 1_fetch/out folder
  sbtools::item_file_download(sb_id, names = filename,
                              destinations = path_to_downloaded_file,
                              overwrite_file = overwrite_file)
  
  # Unzip file
  if(!is.null(name_unzip_folder)){
    unzip_folder_path <- file.path(download_path, name_unzip_folder)
    dir.create(unzip_folder_path, showWarnings = FALSE)
  } else{
    # Taking name of the zip file - Remove '.zip' extension for unzip folder
    unzip_folder_path <- sub('.zip','', path_to_downloaded_file)
  }
  
  # Unzip downloaded zip to subfolder
  unzip(zipfile = path_to_downloaded_file, exdir = unzip_folder_path)
  
  # Find and delete years that are not needed - negate enables inverse matching
  if(!is.null(year)){
    years_collapsed <- year %>% lapply(function(x) paste0(x,'.tif')) %>% paste(collapse = '|')
    files_del <- list.files(unzip_folder_path, full.names = TRUE) %>% stringr::str_subset(years_collapsed, negate = T)
    lapply(files_del, file.remove)
    rm(path_to_downloaded_file, files_del)
  }
  
  final_list <- list.files(unzip_folder_path, full.names = TRUE)
  
  return(final_list)
  
}



