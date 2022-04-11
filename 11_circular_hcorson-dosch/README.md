# Messaging

**Tweet 1:**

![11_Circular_LakeSDF](https://user-images.githubusercontent.com/54007288/162848294-c22f0515-09c2-497b-81dd-c31b8445c785.gif)

* Text:
  * Shoreline development factor is the ratio of the lake shoreline to the circumference of a circle of the same area, aka how circular a lake is 🔵. Here are 100 U.S. lakes, from most to least circular 
* Alt text:
  * A progression of 100 lakes, from an Oxbow lake in Tennessee that is long and sinuous, to the near perfectly circular Big Oak Lake in Missouri. 



**Tweet 2:**

![11_Circular_LakeSDF](https://user-images.githubusercontent.com/54007288/162848314-270f425d-631f-4b5e-b160-abe12a0dee03.png)

* Text:
  * The more complex the lake shape, the larger the shoreline development factor is. This reflects how the lake formed as well as the amount of nearshore habitat. 
* Alt Text:
  * A chart showing the shape of 100 U.S. lakes that are representative of the range of shoreline development factor for U.S. lakes. Lakes are ranked from most squiggly to most round, with a single lake appearing to be a perfect circle. 

Tweet 3:
* Text:
  * For this chart, we used the LAGOS-US LOCUS dataset (Smith et al., 2021) of 479,950 lakes > 1 hectare within the conterminous U.S.: https://portal.edirepository.org/nis/mapbrowse?packageid=edi.854.1 


# Data Source
[LAGOS-US Research Platform](https://lagoslakes.org/lagos-us-overview/). The module used for this visualization was the LAGOS-US LOCUS module, [available on EDI Data Portal]](https://portal.edirepository.org/nis/mapbrowse?packageid=edi.854.1)

_Resources and variables used:_
* 'gis_locus_v1.0.gdb.zip'
  * spatial polygons and Shape area
* 'lake_information.csv'
  * `lagoslakeid`
  * `lake_nhdid`
  * `lake_namegnis`
  * `lake_lat_decdeg`
  * `lake_lon_decdeg`
  * `lake_ismultipart`
  * `lake_centroidstate`
  * `lake_nhdftype`
  * `lake_shapeflag`
* 'lake_characteristics.csv'
  * `lagoslakeid`
  * `lake_waterarea_ha`
  * `lake_shorelinedevfactor`
  * `lake_perimeter_m`

**Citation**: Smith, N.J., K.E. Webster, L.K. Rodriguez, K.S. Cheruvelil, and P.A. Soranno. 2021. LAGOS-US LOCUS v1.0: Data module of location, identifiers, and physical characteristics of lakes and their watersheds in the conterminous U.S. ver 1. Environmental Data Initiative. https://doi.org/10.6073/pasta/e5c2fb8d77467d3f03de4667ac2173ca (Accessed 2022-04-11).

# Tools & libraries used
Python 3.7.6

_Packages:_
* pandas
* numpy
* geopandas
* matplotlib
* cmasher
* imageio
* math
* statistics
* os
