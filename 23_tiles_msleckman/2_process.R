source('2_process/src/read_in_reclassify.R')

p2_targets_list<- list(
  
  ## REclassifie and return folder where new rasters are found
  tar_target(
    p2_write_reclassified_rasters_FOR, 
    {purrr::map(.x = p1_FORESCE_lc_tif_download_filtered, # using just the first 2 tif images for now 
         .f = ~read_in_reclassify(lc_tif_path = .x,
                                  reclassify_legend = reclassify_df_nlcd,
                                  value_cols = c('FORESCE_value','Reclassify_match'),
                                  aoi_crop = drb_boundary,
                                  legend_file_sep = ','))
    },
  ),
  
  tar_target(
    p2_write_reclassified_rasters_NLCD, 
    {purrr::map(.x = list.files(path = '1_fetch/out/nlcd/', full.names = TRUE), # using just the first 2 tif images for now 
                .f = ~read_in_reclassify(lc_tif_path = .x,
                                         reclassify_legend = reclassify_df_nlcd,
                                         value_cols = c('NLCD_value','Reclassify_match'),
                                         legend_file_sep = ','))
    }
  ),
  
  tar_target(
    p2_all_reclassified_rasters,
    append(p2_write_reclassified_rasters_FOR, p2_write_reclassified_rasters_NLCD)
  ),
  # read in rasters from `2_process/out`. Not working with ratify and levelplot otherwise. 
  tar_target(
    p2_reclassified_raster_list,
    {lapply(
      p2_all_reclassified_rasters,
      raster)
      }
  )
)


