source('2_process/src/read_in_reclassify.R')

p2_targets_list<- list(
  
  ## REclassifie and return folder where new rasters are found
  tar_target(
    p2_write_reclassified_rasters, 
    {purrr::map(.x = p1_FORESCE_lc_tif_download[1:2], # using just the first 2 tif images for now 
         .f = ~read_in_reclassify(lc_tif_path = .x,
                                  reclassify_legend = reclassify_df,
                                  value_cols = c('FORESCE_value','Reclassify_match'),
                                  legend_file_sep = ','))
    },
  ), 
  
  # read in rasters from `2_process/out`. Not working with ratify and levelplot otherwise. 
  tar_target(
    p2_reclassified_raster_list,
    {lapply(
      p2_write_reclassified_rasters,
      raster)
      }
  )
)


