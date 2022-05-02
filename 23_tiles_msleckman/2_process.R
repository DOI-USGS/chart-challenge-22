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
  ## convert raster to df for plotting with ggplot2
  tar_target(
    p2_lc_df_list,
    {
      year <- str_sub(p2_reclassified_raster_list, -8, -5)
      as.data.frame(rast(p2_reclassified_raster_list), xy = TRUE) %>%
        rowid_to_column('cell_id') %>% 
        rename(lc = 4) %>% # 4th col are raster values
        mutate(year = year)
    },
    pattern = map(p2_reclassified_raster_list)
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
  tar_target(
    p2_count_ordered,
    p2_raster_cell_count %>% 
      # find % of total area in each category over time
      left_join(p2_raster_cell_count %>% 
                  group_by(year)%>%
                  summarize(total_cells = sum(count))) %>%
      mutate(percent = count/total_cells) %>%
      # order lc by mean % area to stack bars
      mutate(lc_order = forcats::fct_reorder(factor(value), percent, .fun = mean))
  )
)


