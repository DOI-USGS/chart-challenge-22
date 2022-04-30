source('2_process/src/read_in_reclassify.R')
source('2_process/src/downsampling.R')
source('2_process/src/get_pixel_change.R')

p2_targets_list<- list(
  
  ## Reclassified and return reclassified tifs to specified 'reclassified' where new rasters are found
  ## reclassification for the FORESCE backcasting tif files. This needs cropping to the correct polygon boundary
  tar_target(
    p2_write_reclassified_rasters_FOR, 
    {purrr::map(.x = p1_FORESCE_lc_tif_download_filtered, 
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
    c(p2_write_reclassified_rasters_FOR, p2_write_reclassified_rasters_NLCD)
  ),
  
  # Read in rasters from `2_process/out/reclassified`.
  tar_target(
    p2_reclassified_raster_list,
    raster(p2_all_reclassified_rasters),
    pattern = map(p2_all_reclassified_rasters)
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
     downsamp_cat(p2_reclassified_raster_list[[1]], down_fact = 8) %>% 
     mutate(rast = names(p2_reclassified_raster_list[[1]])),
   pattern = map(p2_reclassified_raster_list) 
  ),
  tar_target(
    # picking last raster to use as base grid for resampling
    rast_grid,
    p2_reclassified_raster_list[[13]]
  ),
  ## resample backcasted nlcd to match current dimensions (lower res)
  ## this makes consistent across data sources
  tar_target(
    # resample to same dimensions
    p2_resamp,
    resample_cat_raster(raster = terra::rast(p2_reclassified_raster_list[[1]]),
               raster_grid = terra::rast(rast_grid),
               year = all_years,
               down_fact = 8
               ),
    pattern = map(p2_reclassified_raster_list, rast_years)
    
  ),
  # for each year, calculate difference with next
  tar_target(
    p2_diff,
    get_pixel_change(p2_resamp)
  ),
  tar_target(
    p2_long_sankey,
    p2_diff %>% ggsankey::make_long('1900','1910','1920','1930','1940','1950','1960','1970','1980','1990','2001','2011','2019')
  ),
  tar_target(
    p2_bump_df, 
    p2_diff %>% 
      group_by(year, variable) %>%
      summarize(cells = length(cell_id))
  )
)


