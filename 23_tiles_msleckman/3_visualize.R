source('3_visualize/src/save_lc_img_gif.R')
source('3_visualize/src/raster_plotting_w_ggplot.R')
source('3_visualize/src/lc_levelplot.R')
source('3_visualize/src/bar_plot.R')

p3_targets_list<- list(
  
  # Create output images for each year - tibble for p3_save_levelplot_map_frames target

  # Plotting
  ## Produce bar plot of area through time
  tar_target(
    p3_save_barplot_frames,
    {lapply(X = all_years, FUN = function(x) stacked_bar_plot(counts = p2_raster_cell_count,
                              selected_year = x,
                              legend_df = legend_df, 
                              out_folder = '3_visualize/out/barplot/'))}
  ),
  
  tar_target(
    p3_gif_years,
    c('1900','1910','1920','1930','1940','1950','1960','1970','1980','1990','2001','2011','2019')
  ),
  tar_target(
    # this seems sort of weird, it's to be able to set the x-axis limits for the stacked bar without getting mapped
    p3_all_years, 
    p3_gif_years
  )
  ,
  # Plot land cover through time  # Land cover maps
  tar_target(
    p3_lc_map_fp,
    plot_raster_map(
      year = p3_gif_years,
      raster_df = p2_lc_df_list,
      reach_shp = p1_streams_polylines_drb,
      legend_df = legend_df,
      out_folder = '3_visualize/out/map/'),
    pattern = map(p2_lc_df_list, p3_gif_years),
    format = "file",
  ),
  # Land cover chart
  tar_target(
    p3_lc_chart,
    plot_lc_chart(
      counts = p2_raster_cell_count,
      legend_df = legend_df,
      years = p3_all_years, 
      chart_year = p3_gif_years),
    pattern = map(p2_lc_df_list, p3_gif_years)
  ),
  # Combine chart elements
  #tar_target(
  #  p3_compose_chart,
  #  compse_lc_frames(lc_map = p3_lc_map_fp,
  #  lc_chart = p3_lc_chart,
  #  frame_year = p3_gif_years,
  #  font_fam = "Dongle",
  #  ),
  #  pattern = map(p3_lc_map_fp, p3_lc_chart, p3_gif_years),
  #  format = 'file
  #),
  # Animations
  ## animate levelplot maps
  tar_target(
    p3_animate_levelplot_frames_gif,
    animate_frames_gif(frames = p3_save_levelplot_map_frames,
                       out_file = paste0('3_visualize/out/gifs/levelplot_gif_',today(),'.gif'),
                       reduce = FALSE, frame_delay_cs = 100, frame_rate = 60),
    format = 'file'
  ),

  ## animate barplot maps - need to switch to tar_map 
  tar_target(
    p3_animate_barplot_frames_gif,
    animate_frames_gif(frames = list.files('3_visualize/out/barplot/', full.names = TRUE, pattern = '.png$'),
                       out_file = paste0('3_visualize/out/gifs/barplot_gif_',today(),'.gif'),
                       reduce = FALSE, frame_delay_cs = 100, frame_rate = 60),
    format = 'file'
  ),
  
  ## animate barplot maps - need to switch to tar_map 
  tar_target(
    p3_animate_ggplots_frames_gif,
    animate_frames_gif(frames = list.files('3_visualize/out/ggplots', full.names = TRUE, pattern = '.png$'),
                       out_file = paste0('3_visualize/out/gifs/ggplot_gif_',today(),'.gif'),
                       reduce = FALSE, frame_delay_cs = 100, frame_rate = 60),
    format = 'file'
  ),
  tar_target(
    p3_sankey,
    plot_sankey(p2_long_sankey)
  )
)
