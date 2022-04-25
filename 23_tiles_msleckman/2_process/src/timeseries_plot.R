# Area through time
nlcd_area <- counts %>% 
  # find % of total area in each category over time
  left_join(counts %>% 
              group_by(rast)%>%
              summarize(total_cells = sum(count))) %>%
  mutate(year = as.numeric(stringr::str_sub(rast,-4,-1)),
         percent = count/total_cells) %>%
  filter(value != 0) %>% 
  ggplot(aes(year, 
             percent, 
             group = value, 
             color = factor(value), 
             fill = factor(value))
  ) +
  geom_line(size = 3, alpha = 0.7) +
  geom_point(size = 2, shape = 21, fill = "white", stroke = 1) +
  theme_classic(base_size = 16)+
  scale_y_continuous(
    labels = scales::label_percent(accuracy = 1),
    expand = c(0,0)
  )+
  scale_x_continuous(
    expand = c(0,0)
  ) +
  labs(x="", y="") +
  theme(
    text = element_text(family = font_legend)
    #legend.position = 'none',
    #plot.background = element_blank(),
    #panel.background = element_blank(),
  )+
  scale_color_manual(
    values = legend_df$color,
    labels = legend_df$Reclassify_description,
    "Land cover"
  )+
  scale_fill_manual(
    values = legend_df$color,
    labels = legend_df$Reclassify_description,
    "Land cover"
  )