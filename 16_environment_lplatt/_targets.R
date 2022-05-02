library(targets)

tar_option_set(packages = c(
  "sbtools",
  "scico",
  "sf",
  "tidyverse",
  "usmap"
))

list(

  ##### Phase 1: Download #####

  # Download necessary data from data release
  # https://www.sciencebase.gov/catalog/item/5db761e7e4b0b0c58b5a4978
  tar_target(p1_lake_metadata_csv, sbtools::item_file_download(
    sb_id = '5db8194be4b0b0c58b5a4c3c',
    names = '01_lake_metadata.csv',
    destinations = 'lake_metadata.csv',
    overwrite_file = TRUE), format = 'file'),
  tar_target(p1_lake_spatial_zip, sbtools::item_file_download(
    sb_id = '5db8194be4b0b0c58b5a4c3c',
    names = '01_spatial.zip',
    destinations = 'lake_spatial_data.zip',
    overwrite_file = TRUE), format = 'file'),
  tar_target(p1_lake_thermal_metrics_csv, sbtools::item_file_download(
    sb_id = '5db819bbe4b0b0c58b5a4c47',
    names = '6_glm2pb0_annual_metrics.csv',
    destinations = 'thermal_metrics.csv',
    overwrite_file = TRUE), format = 'file'),

  # Unzip the spatial files
  tar_target(p1_lake_spatial_files, {
    files_out <- zip::zip_list(p1_lake_spatial_zip)$filename
    zip::unzip(zipfile = p1_lake_spatial_zip, files=files_out, overwrite = TRUE)
    return(files_out)
  }, format = 'file'),
  tar_target(p1_study_lakes_shp, p1_lake_spatial_files[grepl('.shp', p1_lake_spatial_files)], format = 'file'),

  ##### Phase 2: Format and prepare the data #####

  # Read in data from files
  tar_target(p2_lakes_metadata, read_csv(p1_lake_metadata_csv)),
  tar_target(p2_thermal_metrics, read_csv(p1_lake_thermal_metrics_csv)),
  tar_target(p2_lakes_sf, st_read(p1_study_lakes_shp)),

  # Get just the lake latitudes
  tar_target(p2_lakes_latitude, p2_lakes_metadata %>% select(site_id, centroid_lat)),

  # Calculate an average summer surface temperature per lake
  # This is used to color the dots on the map and chart
  tar_target(
    p2_avg_summer_lake_temp,
    p2_thermal_metrics %>%
      select(site_id, year, mean_surf_JulAugSep) %>%
      group_by(site_id) %>%
      summarize(avg_summer = mean(mean_surf_JulAugSep, na.rm=TRUE))
  ),

  # Calculate the change in timing of peak surf temp between the first
  # decade and last decade in the dataset, arrange by latitude from N->S
  tar_target(
    p2_peak_day_change,
    p2_thermal_metrics %>%
      # Convert the peak date to a day of year
      mutate(peak_temp_yday = lubridate::yday(peak_temp_dt)) %>%

      # Get avg yday for first 10 and last 10 yrs
      filter(year < 1990 | year > 2008) %>%
      mutate(year_grp = ifelse(year < 1990, "first10", "last10")) %>%
      group_by(site_id, year_grp) %>%
      summarize(avg_yday = mean(peak_temp_yday, na.rm=TRUE)) %>%

      # Calculate a difference between the last decade and first decade
      pivot_wider(id_cols = c(site_id), names_from = year_grp, values_from = avg_yday) %>%
      mutate(change_yday = last10 - first10) %>%
      filter(!is.na(change_yday)) %>% # Remove any that are missing data
      select(site_id, change_yday) %>%
      ungroup() %>%

      # Appropriately order the lakes by latitude
      left_join(p2_lakes_latitude) %>%
      arrange(desc(centroid_lat)) %>%
      mutate(yaxis_ordering = row_number()) %>%

      # Join in each lake's avg summer temp for styling the dots
      left_join(p2_avg_summer_lake_temp)
  ),

  # Prepare lake mapping data
  tar_target(
    p2_lakes_centroids_sf,
    p2_lakes_sf %>%
      st_make_valid() %>%
      st_transform(usmap::usmap_crs()) %>%
      st_centroid() %>%
      left_join(p2_avg_summer_lake_temp)
  ),

  ##### Phase 3: Visualize the data #####

  # This code creates the final two charts which were then manually
  # edited in InkScape to create the final chart.

  tar_target(
    p3_peak_change_chart_png, {
      file_out <- 'peak_temp_change_chart.png'
      ggchart <- ggplot(p2_peak_day_change,
                        aes(x = yaxis_ordering, y = change_yday, color = avg_summer)) +
        geom_point(size=1.5, shape=16) +
        geom_hline(yintercept = 0) +
        scico::scale_color_scico(
          name = "Average summer\ntemperature (degC)",
          palette = 'vikO',
          limits = c(15,35),
          breaks = c(15,25,35)) +
        xlim(nrow(p2_peak_day_change),1) +
        ylim(-25,25) +
        coord_flip() +
        theme(axis.text.y = element_blank(),
              axis.ticks.y = element_blank(),
              axis.title = element_blank(),
              panel.background = element_blank(),
              legend.position="bottom") +
        guides(color = guide_colorbar(
          title.position = "top", barwidth = unit(2,'in'), ticks = FALSE)) +
        ggtitle(sprintf("Seeing earlier peak temps for %s out of %s Midwest lakes",
                        p2_peak_day_change %>% filter(change_yday < 0) %>% nrow(),
                        nrow(p2_peak_day_change)),
                subtitle = "Difference between average day of peak temperature between 1980-1989 and average between 2009-2018")
      ggsave(file_out, ggchart, width = 1600, height = 1800, units = 'px', dpi = 100)
      return(file_out)
    }, format='file'
  ),

  tar_target(
    p3_lakes_map, {
      file_out <- 'peak_temp_change_map.png'
      gglake_map <- usmap::plot_usmap(regions = "states",
                                      include = c('ND', 'SD','IA','MN',
                                                  'WI', 'MI', 'IN', 'IL'),
                                      color = "#9b9c9d", size=0.5) +
        geom_sf(data = p2_lakes_centroids_sf, aes(color = avg_summer), size = 0.8, shape=16, alpha=0.75) +
        scico::scale_color_scico(
          name = "Average summer\ntemperature (degC)",
          palette = 'vikO',
          limits = c(15,35),
          breaks = c(15,25,35)) +
        theme(legend.position="none")
      ggsave(file_out, gglake_map, width = 1600, height = 1800, units = 'px', dpi = 200)
      return(file_out)
    }
  )
)
