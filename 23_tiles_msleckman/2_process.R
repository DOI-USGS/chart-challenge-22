source('2_process/src/read_in_reclassify.R')
source('2_process/src/downsampling.R')

p2_targets_list<- list(
  
  ## Reclassified and return reclassified tifs to specified 'reclassified' where new rasters are found
  ## reclassification for the FORESCE backcasting tif files. This needs cropping to the correct polygon boundary
  tar_target(
    p2_write_reclassified_rasters_FOR, 
    {purrr::map(.x = p1_FORESCE_lc_tif_download_filtered, #[1:2], # using just the first 2 tif images for now
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
    {purrr::map(.x = p1_fetch_nlcd_all_years,
                .f = ~read_in_reclassify(lc_tif_path = .x,
                                         reclassify_legend = reclassify_df_nlcd,
                                         value_cols = c('NLCD_value','Reclassify_match'),
                                         aoi_for_crop = p1_drb_boundary,
                                         legend_file_sep = ',',
                                         out_folder = '2_process/out/reclassified/'))
    }
  ),
  
  ## Combine all paths to tif files
  tar_target(
    p2_all_reclassified_rasters,
    append(p2_write_reclassified_rasters_FOR, p2_write_reclassified_rasters_NLCD)
  ),
  
  # Read in rasters from `2_process/out/reclassified`.
  tar_target(
    p2_reclassified_raster_list,
    {lapply(
      p2_all_reclassified_rasters,
      raster)
      }
  ),
  # count the number of cells for each nlcd category
  # could be used for a paired plot showing area change through time
  tar_target(
    p2_raster_cell_count,
    terra::freq(p2_reclassified_raster_list[[1]]) %>% 
      as_tibble() %>% 
      mutate(rast = names(p2_reclassified_raster_list[[1]])) %>% 
      drop_na(),
    pattern = map(p2_reclassified_raster_list)
  ),
  
  # downsample raster to plot more easily
  # this is over-reduced - gg developed areas notably different from levelplot
  tar_target(
   p2_downsamp_raster_list,
     downsamp_cat(p2_reclassified_raster_list, down_fact = 8)%>% 
     mutate(rast = names(p2_reclassified_raster_list)),
   pattern = map(p2_reclassified_raster_list)
  )
)


