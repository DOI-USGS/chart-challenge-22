# Land Cover Change in the Delaware River Basin

Reconstructed timeseries using modeled historical landscapes from the USGS FORE-SCE model. This R pipeline produces a gif image (adding just the final frame in readme due to size constraints). 

![img_of_gif - non-gif](https://user-images.githubusercontent.com/36547359/166771382-33a2ae84-3e5e-441c-8fd5-9aaa0c3c826d.jpg)


[Data](https://www.sciencebase.gov/catalog/item/605c987fd34ec5fa65eb6a74)


# Description of Viz

120 years of land cover in the Delaware River Basin (1900 to 2020) using @USGS_EROS FORE-SCE model data. #30DayChartChallenge tiles.

This visual shows Land cover animated through time in the Delaware River Basin. The visual shows a map and chart reflecting the proportion of land area in 8 major land cover classes: water, agriculture, barren, forest, grassland, wetland and developed areas (low and high intensity). Time is broken into 10 year intervals. Through time, forest cover replaces agriculture up until 1970. Simultaneously developed areas replace agriculture and grasslands through 2020. Forest is the dominant land cover class. 

Urban areas grew (900%) and agricultural areas declined (-62%). Forested areas in the DRB have also increased during this time period (23%), taking over previous cultivated lands. Land use change is an important driver of environmental change in water basins. For example, more roads and development may mean more road salt deposition in the winter months, which ends up in our waterways and affects river salinity levels. 

## Resources

[FOREcasting SCEnarios of Land-Use Change (FORE-SCE) modeling framework](https://www.usgs.gov/special-topics/land-use-land-cover-modeling/land-cover-modeling-methodology-fore-sce-model)
[FORE-SCE Data Release](https://www.sciencebase.gov/catalog/item/605c987fd34ec5fa65eb6a74)
[EROS NLCD data](https://www.usgs.gov/centers/eros/science/national-land-cover-database)


# Running the R pipeline:

This sub-directory creates an animate map and bar plot visual of land cover change per decade in the Delaware River Basin between 1900 and 2020. The process is built in a targets pipeline which includes a fetch (1_fetch.R), process (2_process.R) and visualize (3_visualize.R) scripts, which divide up the different processes to get the output map. The visualization uses 3 functions - `plot_raster_map()`, `plot_lc_chart()` and `compose_lc_frames()`, and the gif is produced using `animated_frames_gif()`.

To run the pipeline, install `targets` and run `targets::tar_make()` in the console from the subdirectory (`'23_msleckman'`). You may find that you get errors at first if you do not have all of the necessary packages, e.g. `Error : could not find packages cowplot in library paths`. Simply install the packages that are needed and try `targets::tar_make()` again. Repeat as needed. 


