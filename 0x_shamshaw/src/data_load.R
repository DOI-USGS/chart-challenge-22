# Read in streamflow drought event dataset calculated using thresholds calculated based on all data from a given site
streamflow_site <- read_csv("C:/Users/shamshaw/DOI/GS-WMA-DROUGHT RegionalDroughtEarlyWarning - Documents/General/Data/Data_From_National_Project/Streamflow/Drought_Summaries/weibull_site_Drought_Properties.csv") %>% 
  mutate(uniq_drought_id = str_c(StaID,"_",drought_id)) %>%  # add a unique drought ID across all sites
  mutate(decade = as.factor(floor(year(start)/10)*10)) %>% 
  mutate(decade = recode(decade, "2020" = "2010")) %>% # assign 2020 events to 2010-2020 decade
  mutate(onset_month = month(start)) %>% 
  mutate(onset_jd = yday(start)) 

# Read in streamflow drought event dataset calculated using thresholds calculated based on data grouped by julian day by site
streamflow_jd <- read_csv("C:/Users/shamshaw/DOI/GS-WMA-DROUGHT RegionalDroughtEarlyWarning - Documents/General/Data/Data_From_National_Project/Streamflow/Drought_Summaries/weibull_jd_30d_wndw_Drought_Properties.csv") %>% 
  mutate(threshold = as.factor(threshold)) %>% 
  mutate(uniq_drought_id = str_c(StaID,"_",drought_id)) %>% 
  mutate(decade = as.factor(floor(year(start)/10)*10)) %>%
  mutate(decade = recode(decade, "2020" = "2010")) %>% # assign 2020 events to 2010-2020 decade
  mutate(onset_month = month(start)) %>% 
  mutate(onset_jd = yday(start))

# Read in gage metadata
gages <- read_csv("data/all_gages_metadata.csv") %>% 
  rename(StaID = site) %>% 
  # do some recoding of categorical gage characteristics into factors
  mutate(HCDN.2009 = as.factor(HCDN.2009)) %>% 
  mutate(HCDN.2009 = fct_explicit_na(HCDN.2009, na_level = "Non-HCDN")) %>%
  mutate(HCDN.2009 = recode_factor(HCDN.2009, "yes" = "HCDN(2009)" )) %>% 
  mutate(HLR_Description = as.factor(HLR_Description)) %>% 
  mutate(HLR = as.factor(HLR)) %>% 
  mutate(elev_range = as.factor(elev_range)) %>% 
  mutate(DA_range = as.factor(DA_range)) %>%
  mutate(HUC02 = as.factor(HUC02)) %>% 
  mutate(CRB= fct_other(HUC02, keep = c("14", "15"), other_level = 'Outside CRB')) %>% 
  mutate(CRB= recode_factor(CRB, "14" = "Upper Colorado", "15" = "Lower Colorado" )) %>% 
  mutate(HUC02 = recode_factor(HUC02, "10U" = "Upper Missouri", "10L" = "Lower Missouri", "11" = "Arkansas-White-Red", "13" = "Rio Grande", "14" = "Upper Colorado", "15" = "Lower Colorado", "16"="Great Basin", "17" = "Pacific Northwest", "18" = "California" ))

# for primary analysis what threshold are we using  
target_threshold <- 2
target_method <- "jd" # set to jd for Julian Day threshold calcs or #site for All Site theshold calcs