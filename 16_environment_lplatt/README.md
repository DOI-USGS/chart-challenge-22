# Relationships - Environment

This subdirectory creates a chart showing how the timing of peak surface temperature for Midwest lakes has changed between 1980 and 2018.

![earlier_peaks](https://user-images.githubusercontent.com/13220910/166331573-98460efa-ad36-4921-954e-47257ba0b8b5.png)

# Recreating the visual

This subdirectory uses a pipeline with the [`targets` library](https://github.com/ropensci/targets) for R. It takes approximately 50 seconds to run the entire pipeline.

To run the pipeline, install `targets` and run `targets::tar_make()` in the console from the subdirectory (`'16_environment_lplatt'`). You may find that you get errors at first if you do not have all of the necessary packages, e.g. `Error : could not find packages scico in library paths.` Simply install the packages that are needed and try `targets::tar_make()` again. Repeat as needed. You will need the following packages installed: `tidyverse`, `sf`, `usmaps`, `scico`, `sbtools`

The final chart shown above was manually edited in InkScape using the two outputs images from this pipeline - `peak_temp_change_chart.png` and `peak_temp_change_map.png`.

# Data Citation

Jordan S. Read, Alison P. Appling, Samantha K. Oliver, Lindsay Platt, Jacob A. Zwart, Kelsey Vitense, Gretchen J.A. Hansen, Hayley Corson-Dosch, and Holly Kundel, 2021, Data release: Process-based predictions of lake water temperature in the Midwest US: U.S. Geological Survey, http://dx.doi.org/10.5066/P9CA6XP8.
