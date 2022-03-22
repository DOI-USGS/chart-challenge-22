# USGS [#30DayChartChallenge](https://twitter.com/30DayChartChall)

## Chart Info
1. Overall messaging. How does the chart connect to the day/category? What is the 1-2 sentence takeaway?

Only recently have we been able to examine continental patterns in key ecological indicators such as lake color.  This figure displays to physical distribution of lake color and density across space and time along with how those patterns match up to the topographic layout of the U.S.

2. The data source and variables used. Where can the data be found? Is it from USGS or elsewhere? Did you do any pre-processing?

All data used can be downloaded with the provided code.  Key datasets are 1) [LimnoSat-US](https://doi.org/10.5281/zenodo.4139694), which contains all cloud free Landsat observations of U.S. lakes from the HydroLakes database between 1984 and 2020 and 2) elevation data from USGS.

3. Tools & libraries used 
- Stacked topography maps: `rayshader` and `elevatr`
- Temporal Distributions: `ggridges`
- Layout: `gridExtra`, `ggplot`, and `cowplot`

![']
USLakeDist.png