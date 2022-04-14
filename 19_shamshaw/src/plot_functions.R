multi_panel_swarm_plot <- function(...){
  
  combined_swarms <- bind_rows(...)
  
  max_dur <- max(combined_swarms$duration)
  max_rnum <- max(combined_swarms$rnum)
  
  hbreaks <- BAMMtools::getJenksBreaks(combined_swarms$duration, k=10)
  scaledBreaks <- scales::rescale(c(0,hbreaks), c(0,1))
  
  p <- combined_swarms %>% ggplot()+
    geom_hline(yintercept=0, color="#dddddd",size = 1)+
    geom_tile(aes(x=date, y=rnum, fill = duration), height=0.7)+
    scale_fill_scico(values = scaledBreaks, palette = "lajolla", begin = 0.25, end = 1 , 
                     direction = 1, guide_legend(title = "Drought Duration (Days)", title.position = "right"))+
    theme_minimal()+
    ylab(element_blank())+
    xlab(element_blank())+
    theme(axis.text.y=element_blank(),
          panel.grid = element_blank(),
          axis.line.x = element_line(color = "black"),
          strip.text = element_blank(),
          panel.spacing.y=unit(0, "lines"),
          axis.ticks.x = (element_line(size=1)),
          legend.title = element_text(angle = 90))+
    facet_col(vars(decade), scales = "free", space = "free")

  return(p) 
  
}

event_swarm_plot <- function(swarm_data){
  
  max_dur <- max(swarm_data$duration)
  max_rnum <- max(swarm_data$rnum)
  
  hbreaks <- BAMMtools::getJenksBreaks(swarm_data$duration, k=10)
  scaledBreaks <- scales::rescale(c(0,hbreaks), c(0,1))
  
  p <- swarm_data %>% ggplot()+
    geom_hline(yintercept=0, color="#dddddd",size = 1)+
    geom_tile(aes(x=date, y=rnum, fill = duration), height=0.7)+
    scale_fill_scico(values = scaledBreaks, palette = "lajolla", begin = 0.25, end = 1 , direction = 1,
                     guide_legend(title = "Drought Duration (Days)", title.position = "right"))+
    theme_minimal()+
    ylab(element_blank())+
    xlab(element_blank())+
    theme(axis.text.y=element_blank(),
          panel.grid = element_blank(),
          axis.line.x = element_line(color = "black"),
          strip.text = element_blank(),
          panel.spacing.y=unit(0, "lines"))
  
  return(p) 
  
}