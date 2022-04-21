source('3_visualize/src/save_lc_img_gif.R')
source('3_visualize/src/raster_plotting_w_ggplot.R')
source('3_visualize/src/lc_levelplot.R')
source('3_visualize/src/bar_plot.R')


p3_targets_list<- list(
  
  # Create output images for each year
  tar_target(
    gif_frames,
    tibble(raster = p2_reclassified_raster_list,
           seq = seq(1, length(p2_reclassified_raster_list))) # the sequence of the frames
  ),
  
  ## Produce levelplot
  tar_target(
    p3_save_levelplot_map_frames,
    produce_lc_levelplot(raster_in = gif_frames$raster,
                   raster_frame = gif_frames$seq,
                   legend_df = legend_df,
                   reach_shp = NULL,
                   out_folder = "3_visualize/out/levelplot/"),
    pattern = map(gif_frames),
    format = 'file'
    ),

  ## Produce bar_plots as alternative to lined graphic
  tar_target(
    p3_save_barplot_frames,
    lapply(x = all_years,
           function(x)
             stacked_bar_plot(counts = p2_raster_cell_count,
                              selected_year = x,
                              legend_df = legend_df, 
                              out_folder = '3_visualize/out/barplot/'),
           format = 'file'
  ),
  
  tar_target(
    p3_save_map_frames_ggplot,
    raster_ploting_w_ggplot(
      raster_in = p2_downsamp_raster_list,
      reach_shp = p1_streams_polylines_drb,
      counts = p2_raster_cell_count,
      legend_df = legend_df,
      title = "NLCD in the DRB",
      font_fam = "Dongle"),
    pattern = map(p2_downsamp_raster_list),
  format = "file",
  ),
  
  # animate levelplot maps
  tar_target(
    p3_animate_levelplot_frames_gif,
    animate_frames_gif(frames = p3_save_levelplot_map_frames,
                       out_file = paste0('3_visualize/out/levelplot/levelplot_gif_',today(),'.gif'),
                       reduce = FALSE, frame_delay_cs = 100, frame_rate = 60),
    format = 'file'
  ),
  
  # animate levelplot maps
  tar_target(
    p3_animate_barplot_frames_gif,
    animate_frames_gif(frames = p3_save_barplot_frames,
                       out_file = paste0('3_visualize/out/barplot/barplot_gif_',today(),'.gif'),
                       reduce = FALSE, frame_delay_cs = 100, frame_rate = 60),
    format = 'file'
  )
)
