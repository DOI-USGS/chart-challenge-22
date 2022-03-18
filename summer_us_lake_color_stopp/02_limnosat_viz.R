library(tidyverse)
library(leaflet)
library(sf)
library(feather)
library(lubridate)
library(leafgl)
library(mapview)
library(rayshader)
mapviewOptions(fgb=F)

setwd('summer_us_lake_color_stopp/')

## To download the data
#source('01_limnosat_download.R')

## Read in the data
# Lakes
lakes <- st_read('data_in/HydroLakes_DP.shp') %>%
  filter(type=='dp') %>%
  st_centroid() %>%
  st_transform(5070)

#Read in Limnosat
ls <- read_csv('data_in/LimnoSat_20200628.csv')

##Filter it down a bit to make it less unweidly
ls <- ls %>% mutate(month = month(date),
                    doy=yday(date)) %>%
  filter(pCount_dswe3 == 0,
         pCount_dswe1 > 9,
         dWL>470,
         dWL<584,
         month > 4, 
         month < 10) %>%
  mutate(bin=cut_interval(doy,20,labels=F))

#Make a grid of the US to group lakes into
usa <- maps::map('usa', plot = F) %>% 
  st_as_sf() %>%
  st_transform(5070)

world <- ne_countries(scale = "medium", returnclass = "sf") %>%
  st_transform(5070) %>%
  st_crop(.,st_bbox(usa))

mapview(usa)
grid <- st_make_grid(usa, cellsize = c(90000,90000), square = F) %>% st_as_sf() %>% mutate(grid_ID = row_number())
mapview(grid,zcol='grid_ID')

grid_lake_walk <- grid %>% st_join(lakes) %>%
  filter(!is.na(Hylak_id)) %>%
  st_set_geometry(NULL)

## Lets puts around with Elevatr
grid_xy <- st_centroid(grid)
library(elevatr)
grid_elev <- get_elev_point(grid_xy, src = "aws")


## Make a lookup table for forel-ule index colors
#Connect dWL to the forel ule index for visualization
fui.lookup <- tibble(dWL = c(471:583), fui = NA)
fui.lookup$fui[fui.lookup$dWL <= 583] = 21
fui.lookup$fui[fui.lookup$dWL <= 581] = 20
fui.lookup$fui[fui.lookup$dWL <= 579] = 19
fui.lookup$fui[fui.lookup$dWL <= 577] = 18
fui.lookup$fui[fui.lookup$dWL <= 575] = 17
fui.lookup$fui[fui.lookup$dWL <= 573] = 16
fui.lookup$fui[fui.lookup$dWL <= 571] = 15
fui.lookup$fui[fui.lookup$dWL <= 570] = 14
fui.lookup$fui[fui.lookup$dWL <= 569] = 13
fui.lookup$fui[fui.lookup$dWL <= 568] = 12
fui.lookup$fui[fui.lookup$dWL <= 567] = 11
fui.lookup$fui[fui.lookup$dWL <= 564] = 10
fui.lookup$fui[fui.lookup$dWL <= 559] = 9
fui.lookup$fui[fui.lookup$dWL <= 549] = 8
fui.lookup$fui[fui.lookup$dWL <= 530] = 7
fui.lookup$fui[fui.lookup$dWL <= 509] = 6
fui.lookup$fui[fui.lookup$dWL <= 495] = 5
fui.lookup$fui[fui.lookup$dWL <= 489] = 4
fui.lookup$fui[fui.lookup$dWL <= 485] = 3
fui.lookup$fui[fui.lookup$dWL <= 480] = 2
fui.lookup$fui[fui.lookup$dWL <= 475 & fui.lookup$dWL >470] = 1

# Actual Forel-Ule Colors
fui.colors <- c(
  "#2158bc", "#316dc5", "#327cbb", "#4b80a0", "#568f96", "#6d9298", "#698c86", 
  "#759e72", "#7ba654", "#7dae38", "#94b660","#94b660", "#a5bc76", "#aab86d", 
  "#adb55f", "#a8a965", "#ae9f5c", "#b3a053", "#af8a44", "#a46905", "#9f4d04")


## Join LimnoSat to FUI colors to get modal color
ls <- ls %>% left_join(fui.lookup) %>%
  left_join(grid_lake_walk)

Modes <- function(x) {
  ux <- unique(x)
  tab <- tabulate(match(x, ux))
  mode <- ux[tab == max(tab)]
  return(mode)
}

ls_binned_sf <- ls %>% group_by(bin,grid_ID) %>%
  summarise(modal_color = mean(fui,na.rm=T)) %>%
  right_join(grid) %>%
  st_as_sf() %>%
  filter(!is.na(modal_color))

library(gganimate)
library(plotly)
p<- ls_binned_sf %>%
  #filter(bin<5)%>%
  ggplot(.) +
  #geom_sf(data=usa) +
  geom_sf(aes(fill=modal_color,frame=bin)) +
  scale_fill_gradientn(colours=fui.colors) +
  ggthemes::theme_map() +
  theme(legend.position = 'None')

ggplotly(p) %>%
  animation_opts(transition = 0, frame=10, redraw = FALSE)
