
# historical comparison #30DayChartChallenge

This subdirectory creates pieces of a map visualization that compares historical lake temperature and timing. The result is a map of CONUS using angled wheat field vectors to compare lake growing degree days between the past (1981-1990) and present (2011-2020). The vectors are mapped to the number of days earlier or later on the x-axis, and the difference in temperature on the y-axis, resulting in vector angles spanning 360 degrees. The map shows that the SE has strong directional changes towards earlier and warmer GDD. The NE and upper midwest trend towards warmer and later GDD. Western states of UT, WY, ID, and MT all have trends towards later, with colder temperatures in some areas. Along the west coast, this pattern switches to earlier and warmer. The data are from [Daily surface temperature predictions for 185,549 U.S. lakes with associated observations and meteorological conditions (1980-2020)](doi.org/10.5066/P9CEMS0M). 

<img width="1695" alt="220403_historical_compare" src="https://user-images.githubusercontent.com/17803537/161432727-c355bb0d-9764-4f96-9f57-a4ff276e636e.png">


This visualization uses the `targets` R package as a workflow tool. Install it with `install.packages('targets')`. Once you've made that install, there are a few more needed to build the images:

```r
install.packages(c('tidyverse','ncdf4','lubridate','sf','data.table','spData'))
```

Then you can build the images with one command by setting your directory to this file's location (e.g., `setwd('03_historical_jread')`):

```r
targets::tar_make()
```
