## processing nlcd stuff

### Process nlcd data:
library(FedData)

devtools::install_github("ropensci/FedData")
install.packages("devtools")
devtools::install_github("ropensci/FedData", force =TRUE)
## test 

FedData::meve
mapview(FedData::meve)
drb_boundary

drb_raster_2011 <- get_nlcd(drb_boundary, 'drb', year = 2011, dataset = 'landcover') 

drb_boundary <- sf::st_transform(drb_boundary, sf::st_crs(drb_raster_2011))

cropped_drb_raster_2011 <- raster::crop(drb_raster_2011, drb_boundary)

mask_drb_raster_2011 <- raster::mask(drb_raster_2011, drb_boundary)

plot(mask_drb_raster_2011)
plot(streams)
plot(drb_boundary, add = T)

streams <- sf::st_read('./1_fetch/in/study_stream_reaches/study_stream_reaches.shp')

plot(streams$geometry)

streams <- sf::st_transform(streams, crs = sf::st_crs(mask_drb_raster_2011))
plot(mask_drb_raster_2011)
plot(streams$geometry, add = TRUE)

raster_data_frame <- as.data.frame(mask_drb_raster_2011, xy = TRUE) %>% na.omit()

colors <- c("#89C5DA", "#DA5724", "#74D944", "#CE50CA", "#3F4921", "#C0717C", "#CBD588", "#5F7FC7", 
            "#673770", "#D3D93E", "#38333E", "#508578", "#D7C1B1", "#689030", "#AD6F3B")
# "#CD9BCD", 
# "#D14285", "#6DDE88", "#652926", "#7FDCC0", "#C84248", "#8569D5", "#5E738F", "#D1A33D", 
# "#8A7C64", "#599861"

ggplot2::ggplot()+
  geom_raster(raster_data_frame, aes(x = x, y = y, fill = raster_data_frame$drb_NLCD_Land_Cover_2011_value))+
  geom_sf(data = streams)
scale_fill_manual(colors)

discr_colors_fct <- scales::div_gradient_pal(low = "white",
                                             mid = "white", 
                                             high = "midnightblue")
discr_colors <- discr_colors_fct(seq(0, 1, length.out = length(breaks)))
discr_colors

# library(RColorBrewer)
# n <- 20
# qual_col_pals = brewer.pal.info[brewer.pal.info$category == 'qual',]


