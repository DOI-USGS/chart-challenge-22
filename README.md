# USGS chart challenge 2022
The [#30DayChartChallenge is a chart-a-day challenge](https://twitter.com/30DayChartChall) to encourage creativity, exploration, and community in data visualization. For each day of the month of April, there is a prompt that participants create charts to fit within and share on twitter. Each prompt fits within 5 broader categories: comparisons, distributions, relationships, timeseries, uncertainties. This year's categories will be unveiled in stages as April 1st approaches. See this [blog post with the USGS contributions from 2021](https://waterdata.usgs.gov/blog/30daychartchallenge-2021/).

![2022 30 day chart challenge prompts: part-to-whole, pictogram, historical, flora, slope, OWID, physical, mountains, statistics, experimental, circular, The Economist, correlation, 3D, multivariate, environment, connections, OECD data, global change, new tool, don/up, animation, tiles, Financial Times. More prompts coming soon.](https://pbs.twimg.com/media/FNgSDsJXEAAG9kO?format=jpg&name=4096x4096) 

## How to use
This repo is to house code and related files for the charts shared via the @USGS_DataSci account. Each chart should have a subdirectory within this repo using the naming convention `day_prompt_name` (e.g. `/01_part-to-whole_cnell`) that will be populated with associated files. Submit contributions via pull requests and tag @ceenell (R), @hcorson-dosch (python), or both (javascript/other) as reviewers. Tools and languages outside of those listed in the previous sentence are welcomed, and may or may not make sense to document in this repo.

## Submitting your final chart PR
When you are ready for review, submit a PR with your final chart and a brief description that includes: 
1. Overall messaging. How does the chart connect to the day/category? What is the 1-2 sentence takeaway?
2. The data source and variables used. Where can the data be found? Is it from USGS or elsewhere? Did you do any pre-processing?
3. Tools & libraries used 

Do not include: 
1. Data files. Ideally data sources are publicly available and can be pulled in programmatically from elsewhere, like ScienceBase, NWIS, or S3. We will not be distributing previously unreleased datasets. Works-in-progress are great! If you are concerned about sharing your data, let's talk about the best way to appraoch it. 

We will review PRs from a design/conceptual/documentation perspective and not necessarily for the data processing and code itself. However, we are happy to engage with you and troubleshoot with you as you develop your chart. 

## Informal feedback sessions
We will be hosting informal brainstorming/feedback sessions each week through the end of April on Thursdays at 1 pm CT via MS teams. The purpose of these sessions to discuss ideas, data, troubleshooting, and give peer feedback as we develop our charts. It is not required that you attend, but we hope you will join us if this could be valuable to you.



