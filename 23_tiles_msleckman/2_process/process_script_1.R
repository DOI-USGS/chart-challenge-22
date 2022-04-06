# install.packages(c("FedData", "rasterVis", "raster","sp", "rgdal", "reshape2", "treemapify", "ggplot2", "kableExtra", "animation", "scales"))
library(FedData)
library(rasterVis)
library(raster)
library(sp)
library(rgdal)
library(reshape2)
library(treemapify)
library(ggplot2)
library(kableExtra)
library(animation)
library(scales)
library(dplyr)
library(tidyverse)
library(sp)
library(sf)


## Read raster file and stack  
drb_1940 <- raster('1_fetch/out/DRB_Historical_Reconstruction_1680-2010/drb_backcasting_1940.tif')
plot(drb_1940)

files <- list.files(path = '1_fetch/out/DRB_Historical_Reconstruction_1680-2010/', pattern = ".tif")
rasters <- lapply(paste0('1_fetch/out/DRB_Historical_Reconstruction_1680-2010/', files), raster)
# all_rasters <- raster::stack(rasters)

rasters

## this plot is off
# plot(all_rasters)

## Read shapefile of area

# reaches_sf <- sf::st_read('Data/study_stream_reaches/study_stream_reaches.shp')
# reach_sp <- as(sf::st_geometry(reaches_sf), Class = 'Spatial')
# crs(reach_sp) <- crs(rasters[[1]])

# plot(reach_sp)

## load legend 
legend <- read.csv('legend_color_map.csv', sep = ',')

## Add colors  
# legend_colors <- pal_nlcd()
# legend$color <- legend_colors$color

## remove 0 values in all_rasters layer elements. 
## Not sure how to get length of all_rasters layers so using length of rasters list that is the input for this raster stack object all_rasters 
for(i in 1:length(rasters[1:3])){
  print(i)
  rasters[[i]][all_rasters[[i]] == 0] <- NA
}

df <- legend %>% filter(FORESCE_value %in% as.character(unique(all_rasters[[1]])))
# df

## Transform to categorical raster 
rat <- ratify(all_rasters[[1]])

# I used some code from the creator of rasterVis to make a custom legend:
myKey <- list(rectangles=list(col = df$color),
              text=list(lab=df$FORESCE_description),
              space='left',
              columns=1,
              size=2,
              cex=.6)

plt<- levelplot(rat, att='ID', 
                col.regions=df$color,
                par.settings = list(axis.line = list(col = "transparent"), 
                                    strip.background = list(col = 'transparent'), 
                                    strip.border = list(col = 'transparent')), 
                scales = list(col = "transparent"),
                colorkey=F,
                key=myKey)

## THIS DOES NOT WORK
# layer(sp.lines(reach_sp))

# Make a list of years in string format for titles
years_lst <- list("1940", "1950", "1960", "1970", "1980", "1990", "2000")

saveGIF(
  {
    for(i in c(1:nlayers(all_rasters))){
      
      rat<-ratify(all_rasters[[i]])
      
      a<-levelplot(rat, att='ID', 
                   col.regions=df$color,
                   par.settings = list(axis.line = list(col = "transparent"), 
                                       strip.background = list(col = 'transparent'), 
                                       strip.border = list(col = 'transparent')), 
                   scales = list(col = "transparent"),
                   main=paste0("drb land cover ", years_lst[[i]]),
                   colorkey=F,
                   key = colorkey
                   )
      
      print(a)
      
    }
  }, interval=0.8, movie.name="gif_test.gif", ani.width = 1000)

