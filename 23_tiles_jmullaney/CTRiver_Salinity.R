library(dataRetrieval)
library(leaflet)
library(mapview)
library(dplyr)
library(lubridate)
library(rgdal)
library(ggplot2)
library(cowplot)
library(showtext)
library(magick)
library(grid)

#chunk to get site info and shapefile
#station numbers of monitoring sites on the Connecticut River
sites <- c("01194750","01194796")
INFO <- readNWISsite(sites)
Essex <- INFO %>% filter(site_no == "01194750") %>% mutate(name = "  Essex")
Old_Lyme <- INFO %>% filter(site_no == "01194796")%>% mutate(name = "  Old Lyme")
# Get shapefile of tidal wetlands
# #download tidal wetland shapefile at link from below, and place into the RStudio project directory https://ct-deep-gis-open-data-website-ctdeep.hub.arcgis.com/datasets/CTDEEP::tidal-wetlands-1990s/about
path <- "Tidal_Wetlands_1990s-shp/Tidal_Wetlands_1990s.shp"
wt <- readOGR(path,layer = "Tidal_Wetlands_1990s") 
wt = spTransform(wt, CRS("+init=epsg:4326"))
wt$lat = coordinates(wt)[,2]
wt$long = coordinates(wt)[,1]

Salmap <- leaflet(INFO) %>% setView(lng = -72.35, lat = 41.30, zoom=12) %>%
  
  addProviderTiles("Stamen.Terrain") %>%
  
  addScaleBar(position = c("bottomright")) %>% 
  
  addPolygons(data = wt, color = "#444444", weight = 0, smoothFactor = 0.5, 
              opacity = 1.0, fillOpacity = 0.5,
              fillColor = "#D35FB7")%>%
  
  addCircleMarkers(lng = ~dec_long_va, 
                   lat = ~dec_lat_va,  
                   radius = 8.0,
                   color = "black",
                   weight = 1, 
                   fillColor = NA,
                   stroke=T,
                   fillOpacity = 1)  %>% 
  addLabelOnlyMarkers(data = Essex,~dec_long_va, ~dec_lat_va, label =  ~name, 
                      labelOptions =labelOptions(noHide = T, direction = 'top', 
                                                 textOnly = T, style = list("font-weight" = "bold", padding = "3px 8px"), 
                                                 textsize = "18px")) %>% 
  addLabelOnlyMarkers(data = Old_Lyme,~dec_long_va, ~dec_lat_va, label =  ~name, 
                      labelOptions =labelOptions(noHide = T, direction = 'bottom', 
                                                 textOnly = T, style = list("font-weight" = "bold", padding = "3px 8px"), 
                                                 textsize = "18px")) %>% 
  addLabelOnlyMarkers(lng = -72.33, lat = 41.27, label =  "Long Island Sound", 
                      labelOptions = labelOptions(noHide = T, direction = 'bottom', 
                                                  textOnly = T,textsize = "18px")) %>% 
  addLabelOnlyMarkers(lng = -72.402, lat = 41.395, label =  "Connecticut River", 
                      labelOptions = labelOptions(noHide = T, direction = 'bottom', 
                                                  textOnly = T, style = list("font-weight" = "normal", padding = "3px 8px"), 
                                                  textsize = "18px")) 
Salmap

#save a jpg
mapshot(Salmap, file = "CTRiver_map.png", remove_controls = c("zoomControl"))

#Generate some dates on a leap year to be used for plotting
Leap <- tibble(Date_plot = seq(as.Date("2020-01-01"), as.Date("2020-12-31"), by="days"),
               Day = yday(Date_plot)) # Julian day column
Leap

#Essex data
saldat <- readNWISdv("01194750", c("90860","00095"),
                     startDate = "2011-01-01",
                     endDate = "2021-12-31",
                     statCd = "00001") %>%
  mutate(Year = year(Date),
         Day = yday(Date)) %>% 
  left_join(Leap) %>% 
  rename(`Top Salinity` = X_at.Essex.Island.Top_90860_00001, `Bottom Salinity` = X_at.Essex.Island.Bottom_90860_00001) %>%
  mutate(Salinity = if_else(`Top Salinity` < 0.5, "Fresh",
                            if_else(`Top Salinity` >= 0.5 & `Top Salinity` < 5, "Oligohaline",
                                    if_else(`Top Salinity` >= 5 & `Top Salinity` <= 18, "Mesohaline",
                                            if_else(`Top Salinity` > 18, "Polyhaline", NULL)))))
#Old_Lyme data
saldat_ol <- readNWISdv("01194796", c("90860","00095"),
                        startDate = "2011-01-01",
                        endDate = "2021-12-31",
                        statCd = "00001") %>% 
  mutate(Year = year(Date),
         Day = yday(Date)) %>% 
  left_join(Leap) %>%  
  rename(`Top Salinity` = X_Top_90860_00001, `Bottom Salinity` = X_Bottom_90860_00001) %>%
  mutate(Salinity = if_else(`Top Salinity` < 0.5, "Fresh",
                            if_else(`Top Salinity` >= 0.5 & `Top Salinity` < 5, "Oligohaline",
                                    if_else(`Top Salinity` >= 5 & `Top Salinity` <= 18, "Mesohaline",
                                            if_else(`Top Salinity` > 18, "Polyhaline", NULL)))))
#ggplots and cowplot
cols <- c("Fresh" = "#5B85AF", "Oligohaline" = "#DBB36E", "Mesohaline" = "#CC8550", "Polyhaline" = "#D05700")

plot_es <- ggplot(saldat, aes(x = Date_plot, y = Year)) + 
  geom_tile(aes(fill = Salinity), width=1, height=0.8) + 
  scale_fill_manual(values = cols) +
  scale_y_reverse(breaks=seq(2011,2021,1)) + 
  scale_x_date(date_breaks = "2 month",date_labels = "%B") +
  theme(axis.title.y = element_blank()) + 
  theme_classic()+
  xlab(NULL) + 
  ggtitle("Upstream, Essex, CT (01194750)") +
  theme(plot.title = element_text(size = 12)) +
  theme(legend.position = "none") 

plot_ol <- ggplot(saldat_ol, aes(x = Date_plot, y = Year)) + 
  geom_tile(aes(fill = Salinity), width=1, height=0.8) + 
  scale_fill_manual(values = cols) +
  scale_y_reverse(breaks=seq(2011,2021,1)) + 
  scale_x_date(date_breaks = "2 month",date_labels = "%B") +
  theme(axis.title.y = element_blank()) + 
  theme_classic()+
  xlab(NULL) +  
  ggtitle("Downstream, Old Lyme, CT (01194796)") + 
  theme(plot.title = element_text(size = 12), plot.caption = element_text(hjust = 0, face = "italic")) +
  theme(legend.position = "none") 


# logo
usgs_logo <- magick::image_read('../logo/usgs_logo_white.png') %>%
  magick::image_resize('x100') %>%
  magick::image_colorize(100, "black")

# map
ct_map <- magick::image_read('CTRiver_map.png') # not saving?

# add font
font_fam <- 'Roboto'
font_add_google(font_fam, regular.wt = 300, bold.wt = 700) 

# using a second font to numbers that is monospaced 
font_num <- 'Source Sans Pro'
font_add_google(font_num, regular.wt = 300, bold.wt = 700) 
showtext_opts(dpi = 300)
showtext_auto(enable = TRUE)

# legend
p_leg <- get_legend(plot_es + 
                      theme_minimal(base_size = 18)+
                      theme(legend.position = "bottom", 
                            text = element_text(family = font_fam),
                            legend.title = element_text(size = 22),
                            legend.spacing.y = unit(4, 'pt'))+
                      guides(fill = guide_legend(
                        title = "Salinity levels"
                      )))


plot_margin <- 0.025

canvas <- rectGrob(
  x = 0, y = 0, 
  width = 16, height = 9,
  gp = gpar(fill = "white", alpha = 1, col = 'white')
)

# combine plot elements
ggdraw(ylim = c(0,1), xlim = c(0,1)) +
  # a white background
  draw_grob(canvas,
            x = 0, y = 1,
            height = 9, width = 16,
            hjust = 0, vjust = 1)+
  # essex plot
  draw_plot(plot_es + theme(legend.position = "none",
                            axis.title = element_blank(),
                            text = element_text(family = font_fam),
                            axis.text = element_text(size = 16, hjust = 0.5, family = font_num),
                            plot.title = element_text(size = 20)) +
              scale_x_date(expand = c(0,0),
                           date_breaks = "2 month",date_labels = "%B")+
              scale_y_continuous(expand = c(0,0),
                                 breaks=seq(2011,2021,1),
                                 trans  = "reverse"),
            y = 0.55+plot_margin, x = 0+plot_margin,
            height = 0.325, width = 0.6) +
  # old lyme plot
  draw_plot(plot_ol + theme(legend.position = "none",
                            axis.title = element_blank(),
                            text = element_text(family = font_fam),
                            axis.text = element_text(size = 16, hjust = 0.5, family = font_num),
                            plot.title = element_text(size = 20))+
              scale_x_date(expand = c(0,0),
                           date_breaks = "2 month",date_labels = "%B")+
              scale_y_continuous(expand = c(0,0),
                                 breaks=seq(2011,2021,1),
                                 trans  = "reverse"),
            y = 0.2+plot_margin, x = 0+plot_margin,
            height = 0.325, width = 0.6) +
  #  add map panel
  draw_image(ct_map,
            x = 0.65, y = 0.2+plot_margin,
            height = 0.75, width = 0.3,
            ) +
  # shared legend
  draw_plot(p_leg,
            y = 0.03, x = 0.21,
            hjust = 0,
            width = 0.2, height = 0.3) +
  # title
  draw_label("Maximum Daily Salinity on the Lower Connecticut River, 2011-2021", 
             x = plot_margin, y = 1-plot_margin, 
             fontface = "bold", 
             size = 36, 
             hjust = 0, 
             vjust = 1,
             fontfamily = font_fam,
             lineheight = 1.1) +
  # creator
  draw_label("John Mullaney, USGS\nData: NWIS", 
             x = 1-plot_margin, y = plot_margin, 
             fontface = "italic", 
             size = 14, 
             hjust = 1, vjust = 0,
             fontfamily = font_fam,
             lineheight = 1.1) +
  # usgs logo
  draw_image(usgs_logo, x = plot_margin, y = plot_margin, width = 0.1, hjust = 0, vjust = 0, halign = 0, valign = 0)

ggsave('CTRiver_salinity.png',height = 9, width = 16)
