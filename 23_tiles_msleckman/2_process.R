source('2_process/src/read_in_reclassify.R')
source('2_process/src/downsampling.R')
source('2_process/src/get_pixel_change.R')

p2_targets_list<- list(
  # Simplify stream geometries for easier plotting
  tar_target(
    p1_streams_polylines_drb,
    p1_drb_flines %>%
      group_by(streamorde) %>%
      summarize() %>%
      rmapshaper::ms_simplify() %>%
      st_intersection(p1_drb_boundary) %>%
      filter(streamorde > 2)
  ),

  # Crop rasters to DRB and reclassify to fewer, and consistent land cover categories
  ## reclassification for the FORESCE backcasting tif files. This needs cropping to the correct polygon boundary
  tar_target(
    p2_write_reclassified_rasters_FOR,
    read_in_reclassify(lc_tif_path = p1_FORESCE_lc_tif_download_filtered,
                       reclassify_legend = reclassify_df_FOR,
                       value_cols = c('FORESCE_value','Reclassify_match'),
                       aoi_for_crop = p1_drb_boundary,
                       legend_file_sep = ',',
                       out_folder = '2_process/out/reclassified/'),
    pattern = map(p1_FORESCE_lc_tif_download_filtered),
    format = 'file'
  ),
  ## Do same for NLCD rasters
  tar_target(
    p2_write_reclassified_rasters_NLCD, 
    read_in_reclassify(lc_tif_path = p1_fetch_nlcd_all_years,
                       reclassify_legend = reclassify_df_nlcd,
                       value_cols = c('NLCD_value','Reclassify_match'),
                       aoi_for_crop = p1_drb_boundary,
                       legend_file_sep = ',',
                       out_folder = '2_process/out/reclassified/'),
    pattern = map(p1_fetch_nlcd_all_years),
    format = 'file'
  ),
  ## Combine all paths to tif files
  tar_target(
    p2_reclassified_raster_list,
    c(p2_write_reclassified_rasters_FOR, p2_write_reclassified_rasters_NLCD)
  ),
  
  # Look at area change in land cover through time
  ## Count the number of cells for each category 
  tar_target(
    p2_raster_cell_count,
    terra::freq(rast(p2_reclassified_raster_list)) %>% 
      as_tibble() %>% 
      mutate(year = str_sub(names(rast(p2_reclassified_raster_list)), -4, -1)) %>%
      drop_na(),
    pattern = map(p2_reclassified_raster_list)
  ),
  # downsample raster to plot more easily
  # this is over-reduced - gg developed areas notably different from levelplot
  tar_target(
   p2_downsamp_raster_list,
     downsamp_cat(p2_reclassified_raster_list, down_fact = 8) %>% 
     mutate(rast = names(p2_reclassified_raster_list)),
   pattern = map(p2_reclassified_raster_list) 
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


