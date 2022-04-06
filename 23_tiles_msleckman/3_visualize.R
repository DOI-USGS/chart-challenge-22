source('3_process/src/save_lc_img_gif.R')

p3_targets_list<- list(
  
  tar_target(
    p3_save_gif,
    save_lc_img_gif(p2_lc_rasters_reclassified[1:3], colorkey = color_key)
      
    )
  )
  
)