
### Project Members
Alison Appling, Salme Cook, Galen Gorski, Amelia Snyder, Theodore Thompson

### Collaborators
Salme Cook, John Warner

### Contributors
Hayley Corson-Dosch, Cee Nell

# Messaging

This plot illustrates fluctuations of the modelled salt front location in the Delaware Bay in the years 2016 and 2019.
The salt front location is the geographic location where water conditions are acceptable for human consumption
(approximately 250 mg/L). This is also where freshwater from the Delaware River meets saltwater from the Atlantic Ocean.
The Delaware Bay provides drinking water for cities in Delaware, New York, and New Jersey.
Models like COAWST simulate the salt front location giving decision-makers insight to manage its location. Saltwater is too
far upstream causes damage to infrastructure and increases water treatment costs for public water companies.
The prediction from these models also provides insight into how the salt front changes with the weather and tides.
Weather phenomena like hurricanes increase the freshwater flowing into the river thus pushing the salt front oceanward.


# Tools & libraries used
Python 3.7.6, JupyterLab

_Packages:_
* xarray
* pandas
* geopandas
* cartopy
* numpy
* datetime
* matplotlib
* cmocean
* dask
* scipy
* os

# Exploring the Salt Front
The polar plots where created in a Jupyter Notebook. It takes approximately 30 minutes to create all figures.

Currently water scientist at the USGS are working to improve the accuracy of the modelled salt front location by isolating the dominant factors
affecting the salt front. These figures are just one part of an ongoing project reaching that goal. The figures were created from modelled outputs
containing data about the daily river mile location of the salt front. To run the notebook, you must have Jupyter Lab installed with the listed libraries.
It is suggested that you create a new environment when running this notebook. Instructions here.
