#' Function to download NHD v2 flowlines for a given huc8 basin
#' @param huc8 is a character string indicating the huc8 identifier
#' 
fetch_flowlines <- function(huc8 ,include_diversions = FALSE){

  # Fetch huc8 polygon from watershed boundary dataset (WBD)
  huc8_poly <- nhdplusTools::get_huc8(id = huc8)
  
  # Fetch flowlines within huc8 polygon
  huc8_flines <- nhdplusTools::get_nhdplus(AOI = huc8_poly, realization = 'flowline')
  
  # check that flowlines were returned by nhdplusTools; if not, stop.
  if(length(huc8_flines$comid) < 1){
    stop(huc8, ' has failed to download flowlines. Try fetch_flowlines() again.')
  }
  
  # Find reach identifier (i.e., comid) at huc8 outlet
  outlet_comid <- huc8_flines$comid[which.max(huc8_flines$totdasqkm)]
  
  # Refine the network to include all comids upstream of outlet_comid *within the huc8 boundaries*
  # note: upstream search distance is set to some arbitrary, high number
  # to capture all of the upstream tributaries.
  network_comids <- nhdplusTools::get_UT(huc8_flines, comid = outlet_comid, distance = 50000)
  network <- huc8_flines %>%
    filter(comid %in% network_comids) %>%
    {if(include_diversions == FALSE){
        filter(.,streamorde == streamcalc)
      } else {.}
    } %>%
    mutate(huc8_id = huc8)
  
  # check that flowlines were returned by nhdplusTools; if not, stop.
  if(length(network$comid) < 1){
    stop(huc8, ' has failed to download flowlines. Try fetch_flowlines() again.')
  }
  
  return(network)
  
}


#' Function to calculate the circular mean of azimuths calculated
#' between successive nodes that comprise an NHD reach.
#' @param segment character string indicating the reach for which
#' mean azimuth will be estimated.
#' 
calc_azimuth_circ_mean <- function(segment){
  
  # Cast segment to class POINT and estimate azimuth (radians)
  az_radians <- segment %>%
    st_transform(4326) %>%
    st_cast("POINT") %>%
    # compute azimuth between each sequence of points
    lwgeom::st_geod_azimuth() %>%
    suppressWarnings()
  
  # Convert azimuth to degrees
  az_unitcircle <- as.numeric(az_radians)*(180/pi)
  az_degrees <- (az_unitcircle + 360) %% 360      
  az_dat <- data.frame(azimuth_deg = as.numeric(az_degrees),
                       azimuth_rad = as.numeric(az_radians))
  
  # Calculate the circular mean of individual azimuth estimates
  az_circ_mean <- az_dat %>% 
    mutate(sin_az = sin(azimuth_rad),
           cos_az = cos(azimuth_rad)) %>%
    summarize(circ_mean_rad = atan2(sum(sin_az),sum(cos_az))) %>%
    mutate(circ_mean_deg = ((as.numeric(circ_mean_rad)*(180/pi)) + 360) %% 360)
  
  return(az_circ_mean$circ_mean_deg)
}  


#' Function to plot a polar chart displaying the
#' distribution of river azimuth.
#' @param data data frame containing the column azimuth
#' @param title character string indicating chart title
#' 
plot_azimuth <- function(data, cp = coord_polar(), color = "#2171b5", fill = "#08519c", 
                         major_breaks = 45, minor_breaks = 15){

  az_plot <- ggplot(data, aes(x = azimuth, weight = lengthkm)) +
    # instead of adjusting scale_x_continuous to span -5 to 365,
    # center first bin so that it fits between 0-10 (instead of -5 to 5);
    # the remaining bins will be automatically adjusted.
    geom_histogram(binwidth = 10, center = 5,
                   fill = fill, color=color,
                   size = 0.25) + 
    cp +
    scale_x_continuous(expand = c(0,0),
                       breaks = seq(0, 360, by = major_breaks),
                       minor_breaks = seq(0, 360, by = minor_breaks),
                       limits = c(0,360)) + 
    theme_minimal() + 
    theme(rect = element_blank(),
          plot.title = element_text(hjust = 0.5),
          axis.title = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks.y = element_blank())
  
  return(az_plot)
  
}


#' Function to plot river flowlines
#' @param data sf LINESTRING object representing river flowlines; 
#' data must contain the column "streamorde"
#' 
plot_ntw <- function(data,huc8_name){

  ntw_plane_view <- data %>%
    ggplot() + 
    # adjust line width so that flow direction is more intuitive
    geom_sf(aes(size = streamorde/5), color = "gray40") +
    scale_size_identity() +
    theme_void()
  
  return(ntw_plane_view)
  
}


#' Function to draw compass
#' 
plot_compass <- function(pad_x = 1, pad_y = 0, height = 0.8, width = 0.8, units = "cm", text_size = 8){
  
compass <- ggspatial::annotation_north_arrow(
  location = "bl", which_north = "true",
  pad_x = unit(pad_x, units), pad_y = unit(pad_y, units),
  height = unit(height, units),
  width = unit(width, units),
  style = ggspatial::north_arrow_orienteering(
    fill = c("grey70", "white"),
    line_col = "grey20",
    text_size = text_size))
return(compass)

}

