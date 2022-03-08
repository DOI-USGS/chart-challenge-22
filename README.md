# USGS chart challenge 2022
The [#30DayChartChallenge is a chart-a-day challenge](https://twitter.com/30DayChartChall) to encourage creativity, exploration, and community in data visualization. For each day of the month of April, there is a prompt that participants create charts to fit within and share on twitter. Each prompt fits within 5 broader categories: comparisons, distributions, relationships, timeseries, uncertainties. This year's categories will be unveiled in stages as April 1st approaches. See this [blog post with the USGS contributions from 2021](https://waterdata.usgs.gov/blog/30daychartchallenge-2021/).

![2022 30 day chart challenge prompts: part-to-whole, pictogram, historical, flora, slope, OWID, physical, mountains, statistics, experimental, circular, The Economist. More prompts coming soon.](https://pbs.twimg.com/media/FM8RLvKWQAUy5_d?format=jpg&name=4096x4096) 

## How to use
This repo is to house code and related files for the charts shared via the @USGS_DataSci account. Each day will have a subdirectory within this repo (e.g. `/1_part-to-whole` that can be populated with files for the theme. Submit contributions via pull requests and tag @ceenell (R), @hcorson-dosch (python), or both (javascript/other) as reviewers. Tools and languages outside of those listed in the previous sentence are welcomed, and may or may not make sense to document in this repo.

## Submitting a PR
Include an image of the final chart along with a brief description that includes: 
1. Overall messaging. How does the chart connect to the day/category? What is the 1-2 sentence takeaway?
2. The data source and variables used. Where it can be found? Is it from USGS or elsewhere? Did you do any pre-processing?
3. Tools & libraries used 

Do not include: 
1. Data files. Ideally data sources are publicly available and can be pulled in programmatically from elsewhere, like ScienceBase, NWIS, or S3. We do not want to be distributing previously unreleased datasets. If you are concerned about this, we can use some design tricks sell the chart without giving away too much, and use it as a mechanism to conceptually highlight works in progress.

We will review PRs from a design/conceptual/documentation perspecitve and not necessarily for the data processing and code itself. However, we are happy to engage with you and troubleshoot as you develop your chart.
