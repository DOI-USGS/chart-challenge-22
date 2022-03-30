# Part-to-whole transforming state map
This subdirectory creates a gif animation of CONUS warping from a chloropleth map to an area weighted cartogram. In both views, states are filled to reflect the percent of land area that is water. In the area weighted cartogram, states are warped to reflect the proportion of land area to water. This is based on data scraped from the [USGS Water Science School](https://www.usgs.gov/special-topics/water-science-school/science/how-wet-your-state-water-area-each-state).

![water area gif](out/state_by_inland_water.gif)

## Build the gif
This gif is created using a pipeline with the `targets` library for R. It takes approximately 5 minutes to build the gif. The pipeline also outputs a bar chart that ranks each state by their % inland water. These graphics were combined outside of R to create the final gif.

To run the pipeline, install `targets` and run `tar_make()` in the console from the subdirectory. The gif is created using the [`gganimate package`](https://gganimate.com/index.html) to tween between the two transition states - chloropleth and cartogram. The map that the chloropleth is based on is pulled from the [`spData` package](https://github.com/Nowosad/spData). This map is joined to the water area data from the Water Science School, and used as an input to `cartogram_cont` from the [`cartogram`](https://github.com/sjewo/cartogram) package to transform state shapes. 

