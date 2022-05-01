animate_frames_gif <- function(frames, out_file, reduce = TRUE, frame_delay_cs, frame_rate){
  
  #' @description 
  #' @frames
  #' @out_file
  #' @reduce
  #' @frame_delay_cs
  #' @frame_rate

  frames %>%
    image_read() %>%
    image_join() %>%
    image_animate(
      delay = c(rep(frame_delay_cs,length(frames))),
      optimize = TRUE
    ) %>%
    image_write(out_file)
  
  if(reduce == TRUE){
    optimize_gif(out_file, frame_delay_cs)
  }
  
  return(out_file)
}

optimize_gif <- function(out_file, frame_delay_cs) {
  # simplify the gif with gifsicle - cuts size by about 2/3
  gifsicle_command <- sprintf('gifsicle -b -O3 -d %s --colors 256 %s', frame_delay_cs, out_file)
  system(gifsicle_command)
  
  return(out_file)
}