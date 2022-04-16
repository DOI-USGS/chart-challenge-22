library(tidyverse)
library(leaflet)
library(sf)
library(feather)
library(lubridate)
library(leafgl)
library(mapview)
library(rayshader) # Need at least 0.27.4
library(elevatr)
library(ggridges)
library(png)
library(grid)
library(xkcd)

mapviewOptions(fgb=F)

# If you aren't already in the correct sub-folder, get there
viz_subfolder <- '07_physical_distributions_stopp'
if(basename(getwd()) != viz_subfolder) {
  setwd(viz_subfolder)
}


## If you haven't already downloaded the data, run the following. Otherwise, skip this.
# source('01_limnosat_download.R')
## If it times out, data can be accessed manually at
## https://doi.org/10.5281/zenodo.4139694


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
         dWL<584)

#Make a grid of the US to group lakes into
usa <- maps::map('usa', plot = F) %>%
  st_as_sf() %>%
  st_transform(5070)

mapview(usa)

grid <- st_make_grid(usa, cellsize = c(50000,50000), square = F) %>% st_as_sf() %>% mutate(grid_ID = row_number())
grid <- st_join(grid,usa,left=F)

mapview(grid,zcol='grid_ID')

grid_lake_walk <- grid %>% st_join(lakes) %>%
  st_set_geometry(NULL)

## Lets putz around with Elevatr
grid_xy <- st_centroid(grid)
library(elevatr)
elev_rast <- get_elev_raster(grid_xy,z=3)

elev_rast <- raster::crop(elev_rast, st_bbox(usa))
elev_rast <- raster::mask(elev_rast,st_buffer(usa,1e5))
elev_matrix <- raster_to_matrix(elev_rast)
elev_matrix[elev_matrix < -500] = NA
attr(elev_matrix,'crs') <- attr(elev_rast,'crs')
attr(elev_matrix,'extent') <- attr(elev_rast,'extent')

## Make our base layer
elev_matrix %>%
  sphere_shade(texture='desert') %>%
  add_shadow(ray_shade(elev_matrix,zscale=50),0.3) %>%
  add_water(detect_water(elev_matrix,min_area = 100,max_height = 700),color="lightblue") %>%
  plot_3d(elev_matrix, water = T,soliddepth = -10, wateralpha = 1,zscale=100, watercolor = "lightblue",windowsize=1000, triangulate=T,max_error = 0.1)

render_camera(theta=30,phi=20,zoom=0.8)


###########
### Make the color overlays
##########

## Make a lookup table for forel-ule index colors
## Connect dWL to the forel ule index for visualization
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


## Join LimnoSat to FUI colors to get average color
ls <- ls %>% left_join(fui.lookup) %>%
  left_join(grid_lake_walk)

ls_spatial <- ls %>%
  group_by(grid_ID) %>%
  summarise(average_color = median(fui,na.rm=T),
            count = length(unique(Hylak_id))) %>%
  mutate(count_log = log10(count)) %>%
  right_join(grid) %>%
  st_as_sf() %>%
  filter(!is.na(average_color))

## Make our overlay
color_overlay = generate_polygon_overlay(ls_spatial %>% st_transform(attr(elev_matrix,'crs')) %>%
                                           arrange(average_color),
                                         attr(elev_matrix,'extent'),
                                         elev_matrix,
                                         data_column_fill = 'average_color',
                                         palette=fui.colors,
                                         linecolor = 'transparent')

count_overlay <- generate_polygon_overlay(ls_spatial %>% st_transform(attr(elev_matrix,'crs')) %>%
                                            arrange(desc(count_log)),
                                          attr(elev_matrix,'extent'),
                                          elev_matrix,
                                          data_column_fill = 'count_log',
                                          palette=viridis::plasma(50),
                                          linecolor = 'transparent')

render_floating_overlay(color_overlay, elev_matrix,altitude = 220, zscale =1, remove_na=F)
render_floating_overlay(count_overlay,elev_matrix,altitude = 440, zscale =1, remove_na=F)

render_camera(theta=20,phi=25,zoom=.75,fov=0)

render_snapshot(filename='USLakeDist.png')

rgl::rgl.close()


### Read in the png image and format and add legends and aux plots.
img <- readPNG('USLakeDist.png')
g <- rasterGrob(img, interpolate=TRUE)

p_color <- ggplot(ls_spatial) +
  geom_sf(aes(fill=average_color)) +
  scale_fill_gradientn(colors=fui.colors, breaks=c(4,17), labels =c('Bluer','Greener'),name='Median lake color\nover 36 years',
                       guide = guide_colorbar(
                         direction = "horizontal",
                         title.position = "top",
                         label.position = "bottom"))+
  theme(legend.background = element_blank(),
        legend.title = element_text(size=10))

## Double check the overlay matches ggplot
p_color

## Pull the Legend
color_legend <- cowplot::get_legend(p_color)

## Same with counts plot
p_count <- ggplot(ls_spatial %>% st_transform(attr(elev_matrix,'crs'))) +
  geom_sf(aes(fill=count)) +
  scale_fill_gradientn(colors = viridis::plasma(50), name='Number of\nlakes', trans='log10',
                       guide = guide_colorbar(
                         direction = "horizontal",
                         title.position = "top",
                         label.position = "bottom")) +
  theme(legend.background = element_blank(),
        legend.title = element_text(size=10))

p_count

count_legend <- cowplot::get_legend(p_count)

## Make our auxiliary color by day of year and elevation plot
## We'll pull elevations using the deepest point shapefile from LimnoSat
dp <- st_read('data_in/HydroLakes_DP.shp') %>%
  filter(type == 'dp') %>%
  st_transform(st_crs(usa)) %>% st_join(usa, left=F)

dp_elev <- get_elev_point(dp, src = "aws")

ls_elev <- ls %>%
  inner_join(dp_elev %>% st_set_geometry(NULL) %>%
               select(Hylak_id, elevation)) %>%
  filter(!is.na(elevation))

fui_color_walk <- tibble(fui=c(1:21),color = fui.colors)

daily_elev_color <- ls_elev %>%
  mutate(elev_bin = cut_interval(elevation,20,labels=seq(0,3800,200)),
         elev_bin = as.integer(as.character(elev_bin))) %>%
  group_by(doy, elev_bin) %>%
  summarise(fui = as.integer(median(fui, na.rm=T)),
            count = n()) %>%
  filter(count > 50) %>%
  left_join(fui_color_walk)


##### Make our xkcd data man
xrange <- range(daily_elev_color$doy)
yrange <- range(daily_elev_color$elev_bin)
ratioxy <-  diff(xrange) / diff(yrange)

datalines <- data.frame(xbegin=c(30,30),ybegin=c(3100,3100),
                        xend=c(50,100), yend=c(3200,1800))

mapping <- aes(x, y, scale, ratioxy, angleofspine,
               anglerighthumerus, anglelefthumerus,
               anglerightradius, angleleftradius,
               anglerightleg, angleleftleg, angleofneck)

dataman <- data.frame( x=10, y=3100,
                      scale = 300,
                      ratioxy = ratioxy/3,
                      angleofspine =  -pi/2  ,
                      anglerighthumerus = -pi/6,
                      anglelefthumerus = -pi/2 - pi/6,
                      anglerightradius = pi/5,
                      angleleftradius = pi/5,
                      angleleftleg = 3*pi/2  + pi / 12 ,
                      anglerightleg = 3*pi/2  - pi / 12,
                      angleofneck = runif(1, 3*pi/2-pi/10, 3*pi/2+pi/10))

ice_fill = expand_grid(x= unique(daily_elev_color$doy),
                  y=unique(daily_elev_color$elev_bin))

doy_plot <- ggplot(daily_elev_color, aes(x=doy, y = elev_bin)) +
  geom_raster(data=ice_fill, aes(x,y), fill='grey90')+
  geom_raster(aes(fill=color))+
  scale_fill_identity() +
  scale_x_continuous(breaks = seq(5,365,31),
                     labels = c('Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'))+
  xkcdman(mapping, dataman,mask=F) +
  xkcdline(aes(x=xbegin,y=ybegin,xend=xend,yend=yend),
           datalines, xjitteramount = 30,yjitteramount=150,mask=F)+
  annotate('text',x=70,y=3500,label='Winter Ice Cover',family = 'xkcd') +
  annotate('text',x=100,y=1200,label='Spring Algae\nBlooms',family = 'xkcd') +
  labs(y='',title ='How do Mountains Influence Lake Color?',
       subtitle='Distribution of over 42k lakes and their color\nin relation to topography of the US')+
  theme_classic() +
  theme(axis.text.x = element_text(angle=45,vjust=.5),
        axis.title.x = element_blank(),
        plot.title=element_text(hjust=.5,face = 'bold'),
        plot.subtitle = element_text(hjust=.5),
        ) 
doy_plot 

sign_off <- textGrob("Simon Topp, USGS\nData from:\ndoi.org/10.1029/2020WR029123\ndoi.org/10.5281/zenodo.4139694",just='left',x=.1,y=0.4,gp=gpar(fontsize=7))

layout.matrix <- rbind(c(4,4,4,4,4,4,4),
                       c(4,4,4,4,4,4,4),
                       c(4,4,4,4,4,4,4),
                       c(NA,3,1,1,1,1,1),
                       c(NA,2,1,1,1,1,1),
                       c(5,5,1,1,1,1,1))

png("gg_lake_stacks_xkcd.png", width = 5, height = 5,units='in',res=300)
gridExtra::grid.arrange(g, color_legend,
                        count_legend,
                        doy_plot, sign_off,layout_matrix=layout.matrix)
grid.text("Elevation (m)",x=.085,y = unit(0.90,"npc"),gp=gpar(fontsize=8))
dev.off() 



#### Alternate with monthly distributions
ls_temporal <- ls %>% group_by(month, Hylak_id) %>%
  summarise(average_color = median(fui, na.rm=T)) %>%
  filter(!is.na(average_color)) %>%
  mutate(month = month(month,label=T),
         month=factor(month, levels = c('Oct','Nov','Dec','Jan','Feb','Mar','Apr','May','Jun',
                                        'Jul','Aug','Sep')))
img_plot <- qplot(1:10, 1:10, geom="blank") +
  annotation_custom(g, xmin=-Inf, xmax=Inf, ymin=-Inf, ymax=Inf) +
  theme_void() +
  annotation_custom(count_legend, 8,9,8.7,9.7) +
  annotation_custom(color_legend,8,9,6.1,7.1) +
  theme(plot.margin=unit(c(0.5,0.5,0.5,-0.5), "cm"),
        plot.background = element_blank())


time_plot <- ggplot(ls_temporal, aes(x = average_color, y = forcats::fct_rev(month), fill = stat(x))) +
  geom_density_ridges_gradient(scale = 2.5, rel_min_height = 0.01) +
  scale_fill_gradientn(colors = fui.colors) +
  coord_cartesian(xlim=c(1,15)) +
  labs(x = 'Average Color Distribution',y='Month') +
  theme_classic() +
  theme(legend.position = "none",
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        plot.margin=unit(c(0.5,-0.5,0.5,0.5), "cm"))

layout.matrix <- rbind(c(2,2,1,1,1,1),
                       c(2,2,1,1,1,1),
                       c(2,2,1,1,1,1))

full <- gridExtra::grid.arrange(img_plot,time_plot,layout_matrix=layout.matrix)

ggsave('gg_lake_stacks.png',plot=full,width=10,height=7,units='in')
