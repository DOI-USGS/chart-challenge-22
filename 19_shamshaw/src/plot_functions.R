multi_panel_swarm_plot <- function(out_file, swarm1, swarm2, swarm3, swarm4,c_pal, dir){
  
  combined_swarms <- bind_rows(swarm1,swarm2,swarm3,swarm4)
  
  max_dur <- max(combined_swarms$duration)
  max_rnum <- max(combined_swarms$rnum)
  
  hbreaks <- BAMMtools::getJenksBreaks(combined_swarms$duration, k=10)
  scaledBreaks <- scales::rescale(c(0,hbreaks), c(0,1))
  
  p <- combined_swarms %>% ggplot()+
    geom_hline(yintercept=0, color="#dddddd",size = 1)+
    geom_tile(aes(x=date, y=rnum, fill = duration), height=0.7)+
    scale_fill_paletteer_c(c_pal,values = scaledBreaks, direction = dir)+
    theme_minimal()+
    ylab(element_blank())+
    xlab(element_blank())+
    theme(axis.text.y=element_blank(),
          panel.grid = element_blank(),
          axis.line.x = element_line(color = "black"),
          strip.text = element_blank(),
          panel.spacing.y=unit(0, "lines"))+
    #facet_wrap(vars(decade), ncol = 1, scales = "free_x")
    #facet_grid(decade ~ ., scales = "free_x", space = "free_y")
    facet_col(vars(decade), scales = "free", space = "free")

  ggsave(out_file, width = 12, height = 12, dpi = 300)  
  
  
  
}