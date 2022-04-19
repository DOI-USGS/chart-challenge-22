source('2_process/src/read_in_reclassify.R')

p2_targets_list<- list(
  
  ## Reclassified and return in folder where new rasters are found
  ## reclassification for the FORESCE backcasting tif files. This needs cropping to the correct polygon boundary
  tar_target(
    p2_write_reclassified_rasters_FOR, 
    {purrr::map(.x = p1_FORESCE_lc_tif_download_filtered[1:2], # using just the first 2 tif images for now 
         .f = ~read_in_reclassify(lc_tif_path = .x,
                                  reclassify_legend = reclassify_df_FOR,
                                  value_cols = c('FORESCE_value','Reclassify_match'),
                                  aoi_for_crop = p1_drb_boundary,
                                  legend_file_sep = ',', 
                                  out_folder = '2_process/out/reclassified/'))
    },
  ),

  ## Reclassified and return in folder where new rasters are found
  ## reclassification for the nlcd tif files found in the 1_fetch/nlcd/ folder. Already cropped to the correct boundary 
  tar_target(
    p2_write_reclassified_rasters_NLCD, 
    {purrr::map(.x = list.files(path = '1_fetch/out/nlcd/', full.names = TRUE, pattern = '.tif$'),
                .f = ~read_in_reclassify(lc_tif_path = .x,
                                         reclassify_legend = reclassify_df_nlcd,
                                         value_cols = c('NLCD_value','Reclassify_match'),
                                         aoi_for_crop = NULL,
                                         legend_file_sep = ',',
                                         out_folder = '2_process/out/reclassified/'))
    }
  ),
  
  ## Combine all paths to tif files
  tar_target(
    p2_all_reclassified_rasters,
    append(p2_write_reclassified_rasters_FOR, p2_write_reclassified_rasters_NLCD)
  ),
  
  # read in rasters from `2_process/out/reclassified`.
  tar_target(
    p2_reclassified_raster_list,
    {lapply(
      p2_all_reclassified_rasters,
      raster)
      }
  )
)

