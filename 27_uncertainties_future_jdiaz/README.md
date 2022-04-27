# Using data assimilation to forecast stream temperature

1. Overall messaging. How does the chart connect to the day/category? What is the 1-2 sentence takeaway?

This submission is for category 5 "uncertainties" and day 27 "future". Here, we are looking at how probabilistic/uncertain forecasts change for a 1-week prediction window. In addition to viewing how a day's prediction changes as we approach it, we also view how standard forecast uncertainty compares to a forecast that uses data assimilation. The main takeaway is that data assimilation improves our stream temperature forecasts by increasing the probability of values that are closer to the eventual observation.

2. The data source and variables used. Where can the data be found? Is it from USGS or elsewhere? Did you do any pre-processing?

The data are from operational USGS forecasts. These are not publicly available, but they are described in our preprint - https://doi.org/10.31223/X55K7G. There was little-to-no preprocessing performed on the existing data (conversion from R object to csv, then subsetting).

3. Tools & libraries used

The first step of data processing required using R to convert the data from an R object into a csv.

The majority of the code was performed in jupyter notebooks with a python kernel using libraries such as pandas, numpy, matplotlib, and scipy (for clean KDE distribution curves). This is found in the notebook `notebooks/figure_creation-ExtraContext.ipynb`

Initial gif creation used the Windows version of ImageMagick.
