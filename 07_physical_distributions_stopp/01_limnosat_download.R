library(tidyverse)
library(leaflet)
library(sf)
library(feather)
library(lubridate)
library(leafgl)
library(curl)

setwd('07_physical_distributions_stopp/')
## First we need to download the actual database, if you've already downloaded it, skip this first chunk.

## Pull the URLS from the zenodo repo. More information on the contents of these files can be found at
## https://doi.org/10.5281/zenodo.4139694.
ls.urls <- httr::GET("https://zenodo.org/api/records/4139694")
ls.urls <- jsonlite::fromJSON(httr::content(ls.urls, as = "text"))
files <- ls.urls$files
urls <- files$links$download

## Identify/Create the folder you want to store the data in
folder <- 'data_in'
if (file.exists(folder)){
  folder <- paste0(folder,'/')
} else {
  dir.create(folder)
  folder <- paste0(folder,'/')
}

##Download the Deepest point shapefile.  This contains the locations of all the lakes in the database.
## Note: On windows you need mode = 'wb' over the default mode = 'w' for download.file)
grep('DP', urls, value = T) %>% purrr::map(., ~curl_download(., paste0(folder,basename(.)), mode = 'wb'))

## Download the scene metadata.  This includes things like scene cloud cover and sun angle for all the
## remote sensing observations in LimnoSat-US.
meta.url <- grep('SceneMetadata', urls, value = T)
curl_download(meta.url, paste0(folder,basename(meta.url)), mode = 'wb')

## Download the actual LimnoSat Database, here we'll download the .feather version because it's
## a little smaller, if you'd prefer the csv, just swap out the .feather with .csv below
## Note: This takes  a couple minutes because the file is ~3gb. Also, we'll rename the file to be
## more user friendly.
ls.url <- grep('srCorrected_us_hydrolakes_dp_20200628.csv', urls, value = T)
curl_download(ls.url, paste0(folder, 'LimnoSat_20200628.csv'), mode = 'wb')

rm(ls.url, ls.urls, meta.url, urls, files)
