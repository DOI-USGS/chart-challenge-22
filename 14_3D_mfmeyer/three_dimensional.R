### This script is Michael Meyer's contribution to the 2022 Chart Challenge
### hosted by the USGS Geological Survey's Data Science Branch. 
### The prompt for 14 April is: 3-Dimensional, and Michael started thinking
### about change in lake levels across continental scales. Michael also 
### started thinking about how the Rayshader Package (https://www.rayshader.com/)
### could be useful for visualizing regional distributions in lake change and 
### also playing into the larger "3-Dimensional" prompt. 

### Fortunately, the Global Lake area, Climate, and Population (GLCP) dataset
### (https://portal.edirepository.org/nis/mapbrowse?packageid=edi.394.4) contains
### lake surface area data for over 1.42 million lakes globally from 1995-2015, 
### in terms of seasonal, permanent, and total surface water. These data are 
### aggregated from HydroLAKES (https://www.hydrosheds.org/products/hydrolakes)
### as well as the JRC Global Surface Water Dataset
### (nature.com/articles/nature20584). Complete documentation on how the GLCP was
### created can be found in Meyer et al (2020)
### (https://www.nature.com/articles/s41597-020-0517-4). 

### The main goal of this script was to identify trends in lake surface area 
### change, and then visually display the number of lakes that are growing or 
### shrinking in area. 

### DISCLAIMER: This script and analysis is designed around Michael's 
### interpretation of "increasing" and "decreasing". This script is designed 
### to increase transparency of the visualization's creation and invite 
### others to perform their own analyses with the GLCP. 

### This script has 6 main steps: 
### 1. Build models for each lake and extract slope of linear model
### 2. Aggregate coefficients and join with locational data
### 3. Make a high-level 2-Dimensional plot to get a sense of trends
### 4. Build Rayshader for lakes that are decreasing in surface area
### 5. Build Rayshader for lakes that are increasing in surface area
### 6. Save snapshot and movie of Rayshader output
### 7. Export legends to overlay on Rayshader output


# 1. Build models for each lake and extract slope of linear model ---------

library(tidyverse)
library(data.table)
library(RColorBrewer)
library(rayshader)
library(maps)
library(sf)
library(spData)
library(plotly)

proj <- "+proj=lcc +lat_1=30.7 +lat_2=29.3 +lat_0=28.5 +lon_0=-91.33333333333333 +x_0=999999.9999898402 +y_0=0 +ellps=GRS80 +datum=NAD83 +to_meter=0.3048006096012192 +no_defs"

## Load GLCP and filter for lakes within the continental USA

glcp <- fread(file = "glcp.csv", integer64 = "character") %>%
  filter(country == "United States of America",
         centr_lat <= 49.5, 
         centr_lat >= 21) 

usa <- map('usa', plot=F) %>% 
  st_as_sf() %>% 
  st_transform(proj)

sf::sf_use_s2(FALSE)

## Create empty vectors to throw in model parameters and Hylak_ids
unique_lakes <- unique(glcp$Hylak_id)
beta_area <- rep(0, length(unique_lakes))
rsquared_area <- rep(0, length(unique_lakes))

for(i in 1:length(unique_lakes)){
  
  ## Filter for the lake data that we want
  ## Michael chose to z-score lake areas within a lake to understand
  ## how lakes may change in area relative to their 20-year mean area
  filtered_data <- glcp %>%
    filter(Hylak_id == unique_lakes[i]) %>%
    mutate(total_km2_scale = as.vector((scale(total_km2))))
  
  tryCatch({
    ## Build the model, but if it errors, fill NA in for the coefficient
    model_filtered <- lm(total_km2_scale ~ year,
                         data = filtered_data)
  }, error = function(e) {beta_area[i] <<- NA})
  
  if (!is.na(beta_area[i])) {
    ## Extract model coefficient and R-squared value
    beta_area[i] <- model_filtered$coefficients[[2]]
    rsquared_area[i] <- summary(model_filtered)$r.squared
  } 
}

# 2. Aggregate coefficients and join with locational data -----------------

unique_lakes_loc <- glcp %>%
  select(Hylak_id, centr_lat, centr_lon) %>%
  distinct() %>%
  inner_join(x = .,
             y = tibble(unique_lakes, beta_area, rsquared_area),
             by = c("Hylak_id" = "unique_lakes")) 

lake_coords <- unique_lakes_loc %>% 
  # project and extract coordinates for plotting
  st_as_sf(coords = c('centr_lon', 'centr_lat'), crs = 4269) %>%
  st_transform(proj) %>%
  st_coordinates()

unique_lakes_df <- unique_lakes_loc %>%
  mutate(centr_lon = lake_coords[,'X'], centr_lat = lake_coords[,'Y'])


# 3. Make a high-level 2-Dimensional plot to get a sense of trends --------

map_change <- ggplot() +
  geom_sf(data = spData::us_states %>% st_transform(proj), 
          fill = "grey95") +
  geom_sf(data = unique_lakes_loc %>%
            filter(centr_lat >= 21) %>% 
            st_as_sf(coords = c("centr_lon", "centr_lat"),
                     crs = 4269),
          aes(color = as.numeric(beta_area)),
          alpha = 0.5, size = 0.5) +
  scale_color_distiller(palette = "BrBG", direction = 1, 
                        name = "Slope of Change") +
  theme_void()
map_change

# 4. Build Rayshader for lakes that are decreasing in surface area --------

map_shrinking <- ggplot() +
  geom_sf(data = spData::us_states %>% st_transform(proj), 
          fill = "grey95") +
  geom_hex(data = unique_lakes_df %>%
             filter(centr_lat >= 21,
                    beta_area <= -0.01),
           aes(x = centr_lon, y = centr_lat),
          bins = 75, alpha = 0.9) +
  scale_fill_distiller(palette = "YlOrBr", 
                        name = "Number \nof Lakes", 
                       trans = "sqrt", direction = 1) +
  theme_bw() +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        legend.position = "none")

plot_gg(map_shrinking, height=6, width=9, scale = 300,
        multicore=TRUE, preview = FALSE, 
        theta = 30, phi = 30, zoom = 0.5)

render_snapshot(filename = "glcp_rayshader", 
                title_text = "Where are lakes decreasing in surface area?")

# 5. Build Rayshader for lakes that are increasing in surface area --------

map_growing <- ggplot() +
  geom_sf(data = spData::us_states %>% st_transform(proj), 
          fill = "grey95") +
  geom_hex(data = unique_lakes_df %>%
             filter(beta_area >= 0.01),
           aes(x = centr_lon, y = centr_lat),
           bins = 75, alpha = 0.9) +
  scale_fill_distiller(palette = "Blues", 
                       name = "Number \nof Lakes", 
                       trans = "sqrt", direction = 1) +
  theme_bw() +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        legend.position = "top")
map_growing

plot_gg(map_growing, height=6, width=9, scale = 300,
        multicore=TRUE, preview = FALSE, 
        theta = 30, phi = 30, zoom = 0.5)

render_snapshot(filename = "glcp_rayshader", 
                title_text = "Where are lakes increasing in surface area?")

# 6. Save snapshot and movie of Rayshader output --------------------------

render_snapshot(filename = "glcp_rayshader", 
                title_text = "Where are lakes increasing or decreasing in surface area?")

render_movie(filename = "glcp_rayshader", 
             frames = 720, fps = 60)

# 7. Create legends -------------------------------------------------------

library(cowplot)
library(grid)
library(gridExtra)
library(magick)

map_growing_legend <- ggplot() +
  geom_sf(data = spData::us_states %>% st_transform(proj), 
          fill = "grey95") +
  geom_hex(data = unique_lakes_df %>%
             filter(beta_area >= 0.01),
           aes(x = centr_lon, y = centr_lat),
           bins = 75, alpha = 0.9) +
  scale_fill_distiller(palette = "Blues", 
                       name = "Number of Lakes Growing", 
                       trans = "sqrt", direction = 1) +
  theme_bw(base_size = 18) +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        legend.position = "bottom") +
  guides(fill = guide_colorbar(
    direction = "horizontal",
    barwidth = 14,
    title.position = "top",
    panel.background = element_blank(),
    panel.background = element_blank(),
    legend.box.background = element_rect(fill = NA)
  ))

map_shrinking_legend <- ggplot() +
  geom_sf(data = spData::us_states %>% st_transform(proj), 
          fill = "grey95") +
  geom_hex(data = unique_lakes_df %>%
             filter(centr_lat >= 21,
                    beta_area <= -0.01),
           aes(x = centr_lon, y = centr_lat),
           bins = 75, alpha = 0.9) +
  scale_fill_distiller(palette = "YlOrBr", 
                       name = "Number of Lakes Shrinking", 
                       trans = "sqrt", direction = 1) +
  theme_bw(base_size = 18) +
  theme(axis.title = element_blank(),
        axis.text = element_blank(),
        axis.ticks = element_blank(),
        legend.position = "bottom") +
  guides(fill = guide_colorbar(
    direction = "horizontal",
    barwidth = 14,
    title.position = "top",
    panel.background = element_blank(),
    legend.box.background = element_rect(fill = NA)
  ))

# Draw just the legends
legend_grow <- cowplot::get_legend(map_growing_legend)
legend_shrink <- cowplot::get_legend(map_shrinking_legend)

grid.newpage()
png('legend_grow.png', height = 100, width = 300)
grid.draw(legend_grow)
dev.off()

grid.newpage()
png('legend_shrink.png', height = 100, width = 300)
grid.draw(legend_shrink)
dev.off()

