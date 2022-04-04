# Comparison - flora
This subdirectory creates a series of maps and historgrams using Spring leaf out data from the [USA National Phenology Network](https://www.usanpn.org/data/spring_indices), accessed in R via the [`rnpn` package](https://github.com/usa-npn/rnpn). The maps and histograms were compiled into a single visual using a vector design program. 

![spring sprung-01](https://user-images.githubusercontent.com/17803537/161629658-dab12622-2956-43ea-84ec-ab8f370ca287.png)


# Recreating the visuals
This subdirectory uses a pipeline with the [`targets` library](https://github.com/ropensci/targets) for R. It takes approximately 10 minutes to run the entire pipeline.

To run the pipeline, install `targets` and run `targets::tar_make()` in the console from the subdirectory (`'04_flora_cnell'`). You may find that you get errors at first if you do not have all of the necessary packages, e.g. `Error : could not find packages terra, colorspace in library paths`. Simply install the packages that are needed and try `targets::tar_make()` again. Repeat as needed. You will need the following packages installed: `tidyverse`, `rnpn`, `terra`, `raster`, `sf`, `colorspace` 

# Data Citation
USA National Phenology Network. 2022. First Leaf - Spring Index and Daily Spring Index Leaf Anomaly as of 04/04/2022 for the contiguous U.S. USA-NPN, Tuscon, Arizona, USA. http://dx.doi.org/10.5066/F7SN0723
