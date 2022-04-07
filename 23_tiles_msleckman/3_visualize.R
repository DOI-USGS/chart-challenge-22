source('3_visualize/src/save_lc_img_gif.R')
 
p3_targets_list<- list(
  
  # Create output images for each year
  tar_target(
    p3_save_map_frames,
    produce_lc_img(p2_reclassified_raster_list,
                   legend_df = legend_df,
                   out_folder = "3_visualize/out/"),
    format = 'file'
    ),
  
  # animate
  tar_target(
    p3_animate_frames_gif,
    animate_frames_gif(frames = p3_save_map_frames,
                       out_file = paste0('3_visualize/out/gif_',today(),'.gif'),
                       reduce = FALSE, frame_delay_cs = 10, frame_rate = 60),
    format = 'file'
  )
  
   )
