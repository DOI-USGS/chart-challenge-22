
morph_maps <- function(file_out, transition_df, font_fam = "Source Sans Pro"){

  font_add_google(font_fam, regular.wt = 300, bold.wt = 700) 
  showtext_auto()
  
  map_ani <- transition_df %>%
    ggplot() +
    geom_sf(aes(fill = inland_perc*100, 
                group = abb,
                geometry = geometry), 
            color = 'white', 
            size = 0.1, 
            alpha = 0.8
    ) +
    theme_void() +
    scale_fill_scico(
      palette = "bukavu", # new palette added with scico v.1.3
      end = 0.49, 
      begin = 0.1, 
      direction = -1
      ) + 
    ggtitle("Percent area water") +
    theme(legend.position = 'none',
          plot.title = element_text(face = 'bold')) +
    gganimate::transition_states(trans_state, 
                      transition_length = 1,
                      state_length = 1,
                      wrap = TRUE
                      )
  
  # animate
  animate(map_ani, duration = 10, fps = 40,
          height = 9, width = 16, units = 'cm', res = 300)
  anim_save(file_out)
  return(file_out)
}
plot_area_rank <- function(file_out, transition_df){
  transition_df %>%
    ggplot()+
    geom_bar(stat='identity', 
             aes(reorder(abb, inland_perc), inland_perc, fill = inland_perc), 
             width = 0.7)+
    theme_classic(base_size = 10)+
    scale_fill_scico(palette = "bukavu", 
                     end = 0.49, 
                     begin = 0.1, 
                     direction = -1
                     )+
    scale_x_discrete(position = "top") +
    scale_y_continuous(position = "right", 
                       labels = scales::label_percent(accuracy = 1), 
                       trans = "reverse", 
                       expand = c(0,0)) +
    labs(y = "Percent area water", x = "")+
    coord_flip()+
    theme(legend.position  = "none",
          plot.background = element_blank(),
          panel.background = element_blank(),
          axis.text = element_text(size = 10),
          axis.ticks = element_line(size = .25),
          axis.ticks.length = unit(0.5,'mm'),
          axis.line = element_line(size = .25))
  ggsave(file_out, height = 9, width = 4, units = 'in', dpi = 300)
  return(file_out)
}