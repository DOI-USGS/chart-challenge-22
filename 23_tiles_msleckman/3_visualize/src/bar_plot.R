stacked_bar_plot <- function(counts, selected_year, legend_df, out_folder = '3_visualize/out/bar_plots/'){
  
  #' @description Create stacked bar plot of land cover typed
  #' @param counts raster count table 
  #' @param year_selection str. selected year. provide list of years if using lapply
  #' @param out_png output file name for png 
  
  font_legend <- 'Source Sans Pro'
  
  # counts <- p2_raster_cell_count
  # year_selection <- '1990'
  print(selected_year)
  # Area through time + formatting table for proper usage in bar plot

nlcd_area <- counts %>% 
  mutate(year = as.character(stringr::word(rast, 4, 4, sep ='_'))) %>%
  filter(year == selected_year) %>% 
  # find % of total area in each category over time
  left_join(counts %>% 
              group_by(rast) %>%
              summarize(total_cells = sum(count))) %>%
  mutate(percent = count/total_cells)

ggplot(nlcd_area, aes(x = year, y = percent,
                      group = value,
                      fill = factor(value)))+
  geom_bar(stat = 'identity')+
  scale_fill_manual(
    values = legend_df$color,
    labels = legend_df$Reclassify_description,
    "Land cover type"
  )+
  theme_classic()+
  scale_y_continuous(
    labels = scales::label_percent(accuracy = 1),
    expand = c(0,0)
    )
# +
  # theme(
  #   text = element_text(family = font_legend))
  
  ggsave(paste0(out_folder, 'bar_plot_',selected_year,'.png'), height = 9, width = 14)
  
}