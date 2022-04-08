# Krissy Hopkins
# chart Challenge
# April 6, 2022

# Libraries
library(ggplot2)
library(ggthemes)
library(dplyr)
library(tidyr)
library(viridis)
library(ggridges)
library(showtext)
library(MetBrewer)

# Set up font for plots
font_files()[409:414,1:4]
font_add(family = "Univers57", regular = "Univers-Condensed.otf")
showtext_auto()

# Download data from https://www.sciencebase.gov/catalog/item/5bb4de01e4b08583a5da4477
# and put in "in/" folder

# Read in sediment data
DF_data = read.csv("in/SPARROWmodeldat/data1_vTSS/data1_vTSS.csv", stringsAsFactors = FALSE)
DF_predict = read.csv("in/SPARROWmodeldat/predict_TSS/predict_TSS.csv", stringsAsFactors = FALSE)

# HUC12s
DF_HUC = read.csv("in/Catchment_HUC12.csv", stringsAsFactors = FALSE)

# Join data and rename ecoregions
DF_sediment = left_join(DF_data, DF_predict, by = "comid") %>%
  left_join(DF_HUC) %>% 
  drop_na(EcoRegion) %>% 
  mutate(HUC_8) %>%
  filter(EcoRegion != 0) %>% 
  mutate(EcoRegion = case_when(
    EcoRegion %in% c(1,2) ~ "Coastal Plain",
    EcoRegion %in% c(3,4) ~ "Piedmont",
    EcoRegion %in% c(5,6) ~ "Mountains",
    TRUE ~ as.character(EcoRegion) 
  )) %>%
  transform(EcoRegion = factor(EcoRegion, levels = c("Mountains", "Piedmont", "Coastal Plain")))

# Clean up env
rm(DF_data, DF_predict, DF_HUC)

# Calculate incremental yield and combine sources
DF_summary = DF_sediment %>% 
  group_by(HUC_8) %>% 
  summarize(PLOAD_INC_TOTAL_mg.km2 = sum(PLOAD_INC_TOTAL)/sum(IncAreaKm2),
            LandUseChange = sum(PLOAD_INC_NWALTCHG)/sum(IncAreaKm2),
            Agriculture = sum(PLOAD_INC_CROPNWALT_KM2)/sum(IncAreaKm2),
            Development = sum(PLOAD_INC_DEVNWALT_KM2)/sum(IncAreaKm2),
            StreamChannel = sum(PLOAD_INC_SAI_MEAN)/sum(IncAreaKm2) + sum(PLOAD_INC_OPEN)/sum(IncAreaKm2))

# Find ecoregion with the largest area in each HUC8
# Add ecoregion to DF_long
DF_Eco_Top = DF_sediment %>% 
  group_by(HUC_8, EcoRegion) %>% 
  summarize(area = sum(IncAreaKm2)) %>% 
  group_by(HUC_8) %>% 
  top_n(1, area) %>% # Find largest area 
  drop_na(HUC_8)

# Make long DF with different sediment sources
DF_long = DF_summary %>%
  select(HUC_8, LandUseChange, Agriculture, Development, StreamChannel) %>%
  gather(key = "Source", value = "value", -HUC_8) %>%
  left_join(DF_Eco_Top, by = "HUC_8") %>% 
  drop_na(EcoRegion) %>%
 mutate(Source = case_when(
   Source == "LandUseChange" ~ "Land Use Change",
   Source == "StreamChannel" ~ "Stream Channel",
   TRUE ~ Source
 ))
DF_long %>%
  group_by(EcoRegion, Source)%>%
  summarize(n = length(unique(HUC_8)))

# Find largest sediment source per EcoRegion
DF_gather_sediment = DF_long %>% 
  group_by(EcoRegion, Source) %>% 
  summarize(Total_Sediment = sum(value)) %>% 
  group_by(EcoRegion) %>% 
  top_n(2, Total_Sediment) # Find largest area

# Plot
ggplot(DF_long, aes(x = value, y = as.factor(EcoRegion), 
                    fill = Source, color = Source
                    )) +
  geom_density_ridges(scale = 1.8, rel_min_height = 0.01, show.legend = TRUE, 
                      alpha = 0.7, size = 1) +
  scale_x_continuous(expand = c(0.01, 0), limits = c(NA, NA)) +
  scale_y_discrete(expand = c(0.01, 0)) +
  scale_color_manual(values = met.brewer(name = "Isfahan1", n = 4, type = "discrete"))+ # also try Isfahan1, Hiroshige, Egypt
  scale_fill_manual(values = met.brewer(name = "Isfahan1", n = 4, type = "discrete"))+# also try Isfahan1, Hiroshige, Egypt
  labs(title = 'Where is sediment coming from in North Carolina?',
       subtitle = 'Comparing sediment sources for HUC8 basins, data from doi.org/10.5066/P97MV16H.', 
       x = "Sediment per year normalized by area \nMg/km2", y = "Ecoregion") +
  guides(fill = guide_legend(
    title.theme = element_text(face = "bold", size = 16, hjust = 1),
    label.theme = element_text(size = 16),
    label.position = "left",
    title = 'Sediment source',
    keywidth = 2,
    keyheight = 2,
    title.position = "top",
  ),
  #duplicating same legend for fill and color
  color = guide_legend(
    title.theme = element_text(face = "bold", size = 16, hjust = 1),
    label.theme = element_text(size = 16),
    label.position = "left",
    title = 'Sediment source',
    keywidth = 2,
    keyheight = 2,
    title.position = "top",
  ))+
  theme_ridges(font_size = 18, grid = TRUE)+
  theme(axis.text=element_text(size=16),
        axis.title.y = element_text(angle = 0,  hjust = 1, vjust = 0.7, 
          margin = margin(r=-100)), # moves the y axis clsoer to the line
        axis.title=element_text(size = 16, face = "bold"),
        legend.text=element_text(size=16),
        legend.position = c(0.75,0.8),
        plot.title = element_text(size = 24, face = "bold", hjust = -1),
        plot.subtitle = element_text(hjust = -1.1),
        plot.margin = margin(20, 50, 20, 50)# create space on left side of plot to shift title
        )

# Save
ggsave("out/Sparrow_chart.png", 
       plot = last_plot(),
       width = 12, height = 8, units = c("in"),
       dpi = 300)
