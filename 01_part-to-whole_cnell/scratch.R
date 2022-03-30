library(sf)
library(geofacet)

tar_load(state_file)

## part-to-whole
# a cartogram with each state filled by the percent water

# access Contiguous U.S. state map:
proj <- "+proj=lcc +lat_1=30.7 +lat_2=29.3 +lat_0=28.5 +lon_0=-91.33333333333333 +x_0=999999.9999898402 +y_0=0 +ellps=GRS80 +datum=NAD83 +to_meter=0.3048006096012192 +no_defs"
states <- sf::st_transform(spData::us_states, st_crs(proj))
states %>%
  ggplot() +
  geom_sf() +
  theme_void()
states

## state waffle
## tile map
state_grid <- us_state_grid1 #%>% 
  #add_row(row = 7, col = 11, code = "PR", name = "Puerto Rico") #%>% # add PR
  #filter(code != "DC")
state_grid

state_fips <- maps::state.fips %>% 
  distinct(fips, abb) %>%
  add_row(fips = 02, abb = 'AK')%>%
  add_row(fips = 15, abb = 'HI')%>%
  #add_row(fips = 72, abb = 'PR') %>%
  mutate(state_cd = str_pad(fips, 2, "left", pad = "0"))
state_fips

data <- read_csv(state_file)%>% 
  left_join(states, by = c('state' = 'NAME')) %>% 
  rename(name = state) %>%
  left_join(state_fips, by = c('GEOID' = 'state_cd')) %>% 
  mutate(percent_area_water = as.numeric(str_replace(percent_area_water, "%", "")))
data

## grid map

library(showtext)
library(ggh4x)

font_fam = "Almarai"
font_add_google(font_fam, regular.wt = 300, bold.wt = 700) # Monda, Almarai
showtext_auto()

text_color <- 'royalblue'

data  %>% 
  ggplot() +
  geom_bar(stat="identity", aes(name, percent_area_water), fill = "royalblue", width = 1.5)+
  geom_text(aes(x=name, y = percent_area_water+15, 
                label = paste0(percent_area_water, '%')),
            color = text_color)+
  geom_text(aes(x=name, y = 80, 
                label = abb),
            color = text_color,
            hjust = 0.5)+
  scale_y_continuous(limits = c(0, 100), expand = c(0,0))+
  facet_geo(~name, 
            grid = state_grid, 
            label = 'code',
            move_axes = FALSE, scales = "free_x") +
  theme_classic(base_size = 20)+
  theme(aspect.ratio = 0.8,
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        axis.line = element_blank(),
        axis.title = element_blank(),
        panel.background = element_rect(color = "royalblue", size = 2, fill = NA),
        panel.spacing = unit(1, 'pt'),
        plot.background = element_rect(
          fill = 'transparent'
          ),
        strip.placement = "inside",
        strip.background = element_blank(),
       #strip.text = element_text(hjust = 0, 
       #                          vjust = -2, 
       #                          size = 12, 
       #                          color = text_color,
       #                          lineheight = 0),
        strip.text = element_blank(),
        plot.title = element_text(face = "bold", size = 44, color = text_color)) +
  ggtitle("Watery states") 

ggsave('out/watery_states.png')

## try
## waffle chart
 
data %>% str


## waffle chart pictogram


## cartogram
library(cartogram)
library(colorspace)

data_df <- states %>% left_join(data) %>%
  transform(coastal_km2 = as.numeric(gsub(',', '', coastal_km2))) %>%
  replace_na(coastal_km2, 0) %>%
  mutate(inland_perc = inland_km2/total_area_km2,
         coastal_perc = coastal_km2/total_area_km2)
str(data_df)

data_df %>% 
  ggplot() +
  geom_sf() +
  theme_void()

# chloropleth
data_df %>% ggplot() +
  geom_sf(aes(fill = inland_perc*100), color = "white") +
  theme_void() +
  scale_fill_viridis_c(option = "mako", direction = -1) +
  #scico::scale_fill_scico(palette = "lapaz", direction = -1) +
  #ggtitle("Percent area inland water")+
  theme(legend.position = c(0.2, 0.1))+
  guides(fill = guide_colorbar(
    direction = "horizontal",
    barwidth = 15,
    barheight = 0.5,
    title = "percent area water",
    title.position = "top",
    title.vjust = 0.1)) 

# transform shape
carto <- cartogram_cont(data_df, weight = 'inland_perc')
carto
map_cart<-carto %>% 
  ggplot() +
  geom_sf(aes(fill = inland_perc*100), color = "white") +
  theme_void() +
  scale_fill_viridis_c(option = "mako", direction = -1) +
  #scico::scale_fill_scico(palette = "lapaz", direction = -1) +
  #ggtitle("Percent area inland water")+
  theme(legend.position = c(0.2, 0.1))+
  guides(fill = guide_colorbar(
    direction = "horizontal",
    barwidth = 15,
    barheight = 0.5,
    title = "percent area water",
    title.position = "top",
    title.vjust = 0.1)) 

## split and spread
ncarto <- cartogram_ncont(data_df, weight = 'inland_perc')
ncarto
ncarto %>% 
  ggplot() +
  geom_sf(aes(fill = inland_perc)) +
  theme_void() +
  scale_fill_viridis_c(option = "mako", direction = -1) +
  #scico::scale_fill_scico(palette = "lapaz", direction = -1) +
  ggtitle("Percent area inland water")

dorto <- cartogram_dorling(data_df, weight = 'inland_perc')
dorto
dorto %>% 
  ggplot() +
  geom_sf(aes(fill = inland_perc*100), color = "white") +
  theme_void() +
  scale_fill_viridis_c(option = "mako", direction = -1) +
  #scico::scale_fill_scico(palette = "lapaz", direction = -1) +
  #ggtitle("Percent area inland water")+
  theme(legend.position = c(0.2, 0.1))+
  guides(fill = guide_colorbar(
    direction = "horizontal",
    barwidth = 15,
    barheight = 0.5,
    title = "percent area water",
    title.position = "top",
    title.vjust = 0.1)) 


## animate between shapes
library(transformr)
library(tweenr)
library(gganimate)

plot_map <- function(data){
  p <- data %>%
    ggplot() +
    geom_sf(aes(fill = inland_perc*100, geometry = geometry), color = "white") +
    theme_void() +
    scale_fill_viridis_c(option = "mako", direction = -1) +
    #scico::scale_fill_scico(palette = "lapaz", direction = -1) +
    #ggtitle("Percent area inland water")+
    theme(legend.position = c(0.2, 0.1))+
    guides(fill = guide_colorbar(
      direction = "horizontal",
      barwidth = 15,
      barheight = 0.5,
      title = "percent area water",
      title.position = "top",
      title.vjust = 0.1)) 
  ggsave(sprintf('out/%s.png', .frame)
  plot(p)
}


animation <- tween_sf(data_df%>%select(geometry, inland_perc), carto%>%select(geometry, inland_perc),'cubic-in-out', 10) %>%
  keep_state(10)
animation
ani <- lapply(split(animation, animation$.frame), plot_map)
ani %>% str(., max.level = 2)
ani$`1`
ani$`10`
ani$`20`
ani$`30`
ani$`40`
ani$`50`

animate(ani)

animation %>%
  ggplot() +
  geom_sf(aes(fill = inland_perc*100, geometry = geometry), color = "white") +
  theme_void() +
  scale_fill_viridis_c(option = "mako", direction = -1) +
  #scico::scale_fill_scico(palette = "lapaz", direction = -1) +
  #ggtitle("Percent area inland water")+
  theme(legend.position = c(0.2, 0.1))+
  guides(fill = guide_colorbar(
    direction = "horizontal",
    barwidth = 15,
    barheight = 0.5,
    title = "percent area water",
    title.position = "top",
    title.vjust = 0.1))  +
  facet_wrap(~.frame)

carto
combo_df <- bind_rows(carto%>%select(geometry, inland_perc, total_area_km2, abb)%>%mutate(id='% water'),
                      data_df%>%select(geometry, inland_perc, total_area_km2, abb)%>%mutate(id='total area')) %>%
  transform(trans_state = factor(id, ordered = TRUE, levels = c('total area','% water')))
combo_df

area_df <- combo_df %>%
  mutate(scale_area = scale(total_area_km2), scale_perc = scale(inland_perc)) %>%
  mutate(color_var = ifelse(trans_state != 'total area', total_area_km2, inland_perc),
         color_scale = ifelse(trans_state != 'total area', scale_perc, scale_area)) 

library(showtext)
library(colorspace)

font_fam = "Source Sans Pro"
font_add_google(font_fam, regular.wt = 300, bold.wt = 700) # Monda, Almarai
showtext_auto()

morphin_usa <- combo_df%>%
  ggplot() +
  geom_sf(aes(fill = inland_perc*100, geometry = geometry), 
          color = 'white', size = 0.3, alpha = 0.8
          ) +
  theme_void() +
  scale_fill_scico(palette = "bukavu", end = 0.49, begin = 0.1, direction = -1)+
  ggtitle("How wet is your state?")+
  theme(legend.position = c(0.1, 0.1))+
  guides(fill = guide_colorbar(
    direction = "horizontal",
    barwidth = 6,
    barheight = 0.4,
    title = "% water",
    title.position = "top",
    title.vjust = 0.1))+
  transition_states(trans_state, wrap = TRUE)
animate(morphin_usa, duration = 10, fps = 20,
        height = 9, width = 16, units = 'cm', res = 300)
anim_save('out/morphin_land.gif')

combo_df %>% str
combo_df %>%
  ggplot()+
  geom_bar(stat='identity', aes(reorder(abb, inland_perc), inland_perc, fill = inland_perc), width = 0.7)+
  #geom_text(aes(reorder(abb, inland_perc), inland_perc, label = abb), hjust = 1)+
  theme_classic(base_size = 16)+
  scale_fill_scico(palette = "bukavu", end = 0.49, begin = 0.1, direction = -1)+
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
        axis.ticks = element_line(size = .25),
        axis.ticks.length = unit(0.5,'mm'),
        axis.line = element_line(size = .25))
ggsave('out/perc_water.png', height = 8, width = 4, units = 'cm')

 shadin_usa <- area_df%>%
  ggplot() +
  geom_sf(aes(fill = color_scale, geometry = geometry), 
          color = 'white', size = 0.3, alpha = 0.8
  ) +
  theme_void() +
  scale_fill_viridis_c(option = "mako", direction = -1, end = 0.9, begin = 0.2) +
  #scico::scale_fill_scico(palette = "lapaz", direction = -1) +
  ggtitle("U.S. states by {closest_state}")+
  theme(legend.position = c(0.1, 0.1))+
  guides(fill = guide_colorbar(
    direction = "horizontal",
    barwidth = 6,
    barheight = 0.4,
    title = "% water",
    title.position = "top",
    title.vjust = 0.1))+
  transition_states(trans_state, wrap = TRUE)+
  theme(legend.position = 'none')
animate(shadin_usa, duration = 10, fps = 20,
        height = 9, width = 16, units = 'cm', res = 200)
anim_save('out/shadin_land.gif')
