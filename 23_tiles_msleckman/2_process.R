source('2_process/src/read_in_reclassify.R')

p2_targets_list<- list(
  
  tar_target(
    p2_lc_rasters_reclassified, 
    {map(.x = p1_FORESCE_lc_tif_download[1:3],
         .f = ~read_in_reclassify(lc_tif_path = .x,
                                  reclassify_legend = legend_df,
                                  value_cols = c('FORESCE_value','Reclassify_match'),
                                  legend_file_sep = ','))
    }
  )
)


