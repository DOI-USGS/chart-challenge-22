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

# Set up font for plots
font_files()[409:414,1:4]
font_add(family = "Univers57", regular = "Univers-Condensed.otf")
showtext_auto()


# Download data from https://www.sciencebase.gov/catalog/item/5bb4de01e4b08583a5da4477

# Read in data
DF1 = read.csv("in/data1_vTSS/data1_vTSS.csv", stringsAsFactors = FALSE)
DF2 = read.csv("in/predict_TSS/predict_TSS.csv", stringsAsFactors = FALSE)

# Join
DF = left_join(DF2, DF1, by = "comid")
rm(DF2, DF1)
colnames(DF)

# Add HUC12s
DF3 = read.csv("in/Catchment_HUC12.csv", stringsAsFactors = FALSE)
DF = left_join(DF, DF3, by = "comid")

unique(DF3$HUC_8)

# Rename Ecoregions
DF = DF %>% drop_na(EcoRegion)
DF = DF %>% filter(EcoRegion != 0)
unique(DF$EcoRegion)

# Rename and combine
DF$EcoRegion[DF$EcoRegion == 1] <- "Coastal Plain" #Middle Atlantic Coastal Plain
DF$EcoRegion[DF$EcoRegion == 2] <- "Coastal Plain" #Southeastern Plains
DF$EcoRegion[DF$EcoRegion == 3] <- "Piedmont" #Northern Outer Piedmont
DF$EcoRegion[DF$EcoRegion == 4] <- "Piedmont" #Piedmont
DF$EcoRegion[DF$EcoRegion == 5] <- "Mountains" #Blue Ridge
DF$EcoRegion[DF$EcoRegion == 6] <- "Mountains" #Ridge and Valley

DF$EcoRegion = factor(DF$EcoRegion, levels = c("Mountains", "Piedmont", "Coastal Plain"))

unique(DF$EcoRegion)

# Calculate incremental yield and combine sources
DF_summary = DF %>% group_by(HUC_8) %>% summarize(PLOAD_INC_TOTAL_mg.km2 = sum(PLOAD_INC_TOTAL)/sum(IncAreaKm2),
                   LandUseChange = sum(PLOAD_INC_NWALTCHG)/sum(IncAreaKm2),
                   Agriculture = sum(PLOAD_INC_CROPNWALT_KM2)/sum(IncAreaKm2),
                   Development = sum(PLOAD_INC_DEVNWALT_KM2)/sum(IncAreaKm2),
                   StreamChannel = sum(PLOAD_INC_SAI_MEAN)/sum(IncAreaKm2) + sum(PLOAD_INC_OPEN)/sum(IncAreaKm2))

DF_Sub = DF_summary[,c(1,3:6)]
DF_gather = gather(DF_Sub, key = "Source", value = "value", -HUC_8)

# Find ecoregion with the largest area in each HUC8
# Add ecoregion to DF_gather
DF_Eco = DF %>% 
  group_by(HUC_8, EcoRegion) %>% 
  summarize(area = sum(IncAreaKm2))
DF_Eco_Top = DF_Eco %>% group_by(HUC_8) %>% top_n(1, area) # Find largest area
DF_Eco_Top = DF_Eco_Top %>% drop_na(HUC_8)

DF_gather = left_join(DF_gather, DF_Eco_Top, by = "HUC_8")
DF_gather = DF_gather %>% drop_na(EcoRegion)

# Find largest source per EcoRegion
DF_gather_sediment = DF_gather %>% 
  group_by(EcoRegion, Source) %>% 
  summarize(Total_Sediment = sum(value))

DF_gather_sediment_top = DF_gather_sediment %>% group_by(EcoRegion) %>% top_n(2, Total_Sediment) # Find largest area


# Plot
ggplot(DF_gather, aes(x = value, y = as.factor(EcoRegion), fill = Source)) +
  geom_density_ridges_gradient(scale = 2, rel_min_height = 0.01, gradient_lwd = 2, show.legend = TRUE) +
  scale_x_continuous(expand = c(0.01, 0)) +
  scale_y_discrete(expand = c(0.01, 0)) +
  scale_fill_viridis(name = "Source", discrete = TRUE, alpha = 0.8) +
  labs(title = 'Where is sediment coming from in North Carolina?',
       subtitle = 'Comparing sediment sources for HUC8 basins, data from doi.org/10.5066/P97MV16H.', 
       x = "Sediment per year normalized by area \nMg/km2", y = "Ecoregion") +
  theme_ridges(font_size = 18, grid = TRUE)+
  theme(axis.text=element_text(size=16),
        axis.title=element_text(size=16),
        legend.text=element_text(size=16),
        legend.position= c(0.7,0.8))

colnames(DF)

# Save
# This isnt working well.
ggsave("out/Sparrow_chart.tiff", 
       plot = last_plot(),
       width = 6, height = 4, units = c("in"),
       dpi = 300)
