### This script is Michael Meyer's contribution to the 2022 Chart Challenge
### hosted by the USGS Geological Survey's Data Science Branch. 
### The prompt for 01 April is: Parts-to-Whole, and Michael started thinking
### about ecological community compositions, and how different member groups 
### of a community can vary in their nutritional content. More specifically,
### Michael started thinking about how phytoplankton taxa often contain a
### consistent mixture of fatty acids (think Omega-3), and how if you know a
### given algal community composition, you can estimate the assemblage of 
### fatty acids that are present within the community. 

### Fortunately, the US Environmental Protection Agency's National Lake 
### Assessment contains biovolume estimates by algal species counted. 
### Additionally, Galloway & Winder (2015; 
### https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0130053)
### contains the most extensive, interoperable dataset for phytoplankton 
### fatty acid compositions. So, we can combine these two datasets through 
### common taxonomic groupings, to get an idea of how essential fatty acid
### ratios are distributed throughout the US per the 2017 NLA survey. '

### This script has 3 main steps: 
### 1. Aggregate biovolumes for the NLA by site
### 2. Aggregate characteristic fatty acid proportions for each taxon
### 3. Combine data outputs from Steps 1 and 2, and then visualize

library(tidyverse)
library(maps)
library(scatterpie)

### Load the necessary data

# NLA 2017 Phytoplankton data 
# https://www.epa.gov/national-aquatic-resource-surveys/data-national-aquatic-resource-surveys
nla_2017_url <- 'https://www.epa.gov/sites/default/files/2021-04/nla_2017_phytoplankton_taxa-data.csv'
download.file(nla_2017_url, "in/nla_2017_phytoplankton_count-data.csv")
nla_phyto <- read.csv("in/nla_2017_phytoplankton_count-data.csv")

# Download fatty acid data from article
# https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0130053
pone_url <- 'https://doi.org/10.1371/journal.pone.0130053.s001'
download.file(pone_url, destfile = 'in/pone.0130053.s001.csv')
fatty_acids <- read.csv("in/pone.0130053.s001.csv") 

# Step 1: Aggregate biovolumes for NLA data by site -----------------------

head(nla_phyto)

nla_phyto_agg <- nla_phyto %>%
  group_by(UID, SITE_ID, LAT_DD83, LON_DD83, ALGAL_GROUP, CLASS) %>%
  summarize(across(.cols = c(ABUNDANCE:DENSITY), .fns = median)) %>%
  ungroup() %>%
  mutate(CLASS = tolower(CLASS))

ggplot() +
  geom_polygon(data = map_data("state"),
               aes(x=long, y=lat, group=group),
               fill="white", color="black", size=.5, alpha = 0) +
  geom_point(data = nla_phyto %>%
               group_by(UID, SITE_ID, LAT_DD83, LON_DD83, ALGAL_GROUP) %>%
               summarize(across(.cols = c(ABUNDANCE:DENSITY), .fns = mean)) %>%
               filter(ALGAL_GROUP != "",
                      ALGAL_GROUP != "YELLOW-GREEN ALGAE"),
          aes(x = LON_DD83, y = LAT_DD83, 
              fill = log10(BIOVOLUME+1), 
              color = log10(BIOVOLUME+1)), alpha = 0.65) +
  scale_fill_viridis(option = "mako") +
  scale_color_viridis(option = "mako") +
  ggtitle("Biovolume of Algal Group") +
  xlab("Logitude") +
  ylab("Latitude") +
  facet_wrap(~ALGAL_GROUP) +
  theme_bw() + 
  theme(plot.title = element_text(size = 18),
        strip.text = element_text(size = 16), 
        axis.text = element_text(size = 10),
        axis.title = element_text(size = 16),
        legend.text = element_text(size = 14),
        legend.title = element_text(size = 16),
        legend.position = "right") 

ggsave('out/phyto_biovol.png', width = 16, height = 9)

nla_phyto_agg_wide <- nla_phyto_agg %>%
  ungroup() %>%
  filter(ALGAL_GROUP != "") %>%
  group_by(UID, ALGAL_GROUP) %>%
  summarize(total_biovolume = sum(BIOVOLUME)) %>%
  ungroup() %>%
  pivot_wider(names_from = ALGAL_GROUP, values_from = total_biovolume) 
  

# Step 2: Aggregate the Fatty Acid Data -----------------------------------

head(fatty_acids)

fatty_acids_agg <- fatty_acids %>%
  select(Class, sumSAFA:c22.6w3) %>%
  mutate(Class = tolower(Class)) %>%
  pivot_longer(cols = c(sumSAFA:c22.6w3), 
               names_to = "fatty_acid", 
               values_to = "prop") %>%
  group_by(Class, fatty_acid) %>%
  summarize(mean_prop = mean(prop)) %>%
  pivot_wider(names_from = fatty_acid, values_from = mean_prop)

fatty_acids_agg

# Step 3: Join datasets and visualize -------------------------------------

phyto_fa_omega <- inner_join(x = nla_phyto_agg, 
                       y = fatty_acids_agg, 
                       by = c("CLASS" = "Class")) %>%
  pivot_longer(cols = c(c18.2w6:sumSAFA), 
               names_to = "fatty_acid", 
               values_to = "prop") %>%
  mutate(biovolume_fa = BIOVOLUME * prop) %>%
  select(-prop) %>%
  mutate(omega = case_when(fatty_acid %in% c("c18.3w3", "c18.4w3", "c18.5w3",
                                             "c20.5w3", "c22.6w3") ~ "omega_3",
                           fatty_acid %in% c("c18.3w6", "c18.2w6" ,
                                             "c20.4w6") ~ "omega_6",
                           fatty_acid == "sumMUFA" ~ "sumMUFA",
                           fatty_acid == "sumPUFA" ~ "sumPUFA",
                           fatty_acid == "sumSAFA" ~ "sumSAFA")) %>%
  group_by(UID, SITE_ID, LAT_DD83, LON_DD83, omega) %>%
  summarize(sum_biovol_fa = sum(biovolume_fa)) %>%
  pivot_wider(names_from = omega, values_from = sum_biovol_fa)

phyto_fa_dia_chloro <- inner_join(x = nla_phyto_agg, 
                             y = fatty_acids_agg, 
                             by = c("CLASS" = "Class")) %>%
  pivot_longer(cols = c(c18.2w6:sumSAFA), 
               names_to = "fatty_acid", 
               values_to = "prop") %>%
  mutate(biovolume_fa = BIOVOLUME * prop) %>%
  select(-prop) %>%
  mutate(source = case_when(fatty_acid %in% c("c18.3w3", "c18.4w3") ~ "green",
                           fatty_acid %in% c("c20.5w3") ~ "diatom")) %>%
  filter(!is.na(source)) %>%
  group_by(UID, SITE_ID, LAT_DD83, LON_DD83, source) %>%
  summarize(sum_biovol_fa = sum(biovolume_fa)) %>%
  pivot_wider(names_from = source, values_from = sum_biovol_fa)

## Plot the geom_scatterpies by fatty acid group: Saturated, Monounsaturated, 
## Polyunsaturated

ggplot() +
  geom_polygon(data = map_data("state"),
               aes(x=long, y=lat, group=group),
               fill="grey95", color="black", size=.5, alpha = 0.7) +
  geom_scatterpie(data = phyto_fa_omega %>% 
                    filter(!is.na(LON_DD83)) %>%
                    #ungroup() %>%
                    #slice_sample(prop = 0.5) %>%
                    group_by(UID, SITE_ID, LAT_DD83, LON_DD83) %>%
                    pivot_longer(cols = c("sumMUFA", "sumPUFA", "sumSAFA"),
                                 names_to = "fatty_acid",
                                 values_to = "value") %>%
                    mutate(sum_fa = sum(value, na.rm = TRUE),
                           prop = value/sum_fa,
                           LON_DD83 = as.numeric(LON_DD83),
                           LAT_DD83 = as.numeric(LAT_DD83)) %>%
                    ungroup() %>%
                    mutate(fatty_acid = factor(fatty_acid, 
                                                levels = c("sumSAFA",
                                                           "sumMUFA", 
                                                           "sumPUFA"))) %>%
                    select(-value) %>%
                    rename(value = prop),
             aes(x = LON_DD83, 
                 y = LAT_DD83,
                 group = UID, r =  0.2),
             alpha = 0.55, cols= "fatty_acid", long_format = TRUE) +
  # scale_color_gradientn(colors = viridis(100)[c(30, 45, 80, 90, 99)], 
  #                       name = "PUFA:SAFA") +
  # scale_fill_gradientn(colors = viridis(100)[c(30, 45, 80, 90, 99)],
  #                      name = "PUFA:SAFA") +
  scale_fill_manual(values = plasma(30)[c(3, 15, 28)], 
                    name = "Fatty Acid Group", 
                    labels = c("sumSAFA" = "Saturated",
                            "sumMUFA" = "Monounsaturated" , 
                      "sumPUFA" = "Polyunsaturated")) +
  xlab("Logitude") +
  ylab("Latitude") +
  theme_bw() + 
  theme(plot.title = element_text(size = 18),
        strip.text = element_text(size = 16), 
        axis.text = element_text(size = 10),
        axis.title = element_text(size = 16),
        legend.text = element_text(size = 14),
        legend.title = element_text(size = 16),
        legend.position = "right")

ggsave('out/fatty_acid_pies.png', width = 16, height = 9)

## Remember - not all Polyunsaturated fatty acids are the same! We have 
## Omega-3s and Omega-6s, so one way to assess the nutritional content 
## can be to further split the types of PUFAs in each system. 

## Let's look at the omega-3:omega-6 ratio!
ggplot() +
  geom_polygon(data = map_data("state"),
               aes(x=long, y=lat, group=group),
               fill="grey95", color="black", size=.5, alpha = 0.7) +
  geom_point(data = phyto_fa_omega %>% 
                    filter(!is.na(LON_DD83)),
                  aes(x = LON_DD83, 
                      y = LAT_DD83,
                      fill = omega_3/omega_6,
                      color = omega_3/omega_6),
                  alpha = 0.55, size = 3) +
   scale_color_gradientn(colors = viridis(100)[c(30, 45, 80, 90, 99)], 
                         name = "Omega-3:Omega6") +
   scale_fill_gradientn(colors = viridis(100)[c(30, 45, 80, 90, 99)],
                        name = "Omega-3:Omega6") +
  #ggtitle("Polyunsaturated Fatty Acids: Saturated Fatty Acids") +
  xlab("Logitude") +
  ylab("Latitude") +
  theme_bw() + 
  theme(plot.title = element_text(size = 18),
        strip.text = element_text(size = 16), 
        axis.text = element_text(size = 10),
        axis.title = element_text(size = 16),
        legend.text = element_text(size = 14),
        legend.title = element_text(size = 16),
        legend.position = "right")

ggsave('out/omega_ratio.png', width = 16, height = 9)
