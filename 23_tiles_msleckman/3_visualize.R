source('3_visualize/src/save_lc_img_gif.R')
source('3_visualize/src/raster_plotting_w_ggplot.R')

p3_targets_list<- list(
  
  # Create output images for each year
  tar_target(
    gif_frames,
    tibble(raster = p2_reclassified_raster_list,
           seq = seq(1, length(p2_reclassified_raster_list))) # the sequence of the frames
  ),
  tar_target(
    p3_save_map_frames,
    produce_lc_img(raster_in = gif_frames$raster,
                   raster_frame = gif_frames$seq,
                   legend_df = legend_df_FOR,
                   out_folder = "3_visualize/out/"),
    pattern = map(gif_frames),
    format = 'file'
    ),

  tar_target(
    p3_save_map_frames_ggplot,
    raster_ploting_w_ggplot(
      raster_in = p2_downsamp_raster_list,
      reach_shp = p1_streams_polylines_drb,
      legend_df = legend_df_FOR,
      out_folder = "3_visualize/out/"),
    pattern = map(p2_downsamp_raster_list),
    format = 'file'
  ),

  
  # animate
  tar_target(
    p3_animate_frames_gif,
    animate_frames_gif(frames = p3_save_map_frames,
                       out_file = paste0('3_visualize/out/gif_',today(),'.gif'),
                       reduce = FALSE, frame_delay_cs = 100, frame_rate = 60),
    format = 'file'
  )
)
