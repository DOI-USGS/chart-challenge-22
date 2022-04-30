get_pixel_change <- function(rast_in){
  
  rast_cat <- rast_in %>% 
    data.table::melt(id.vars = c('cell_id','year')) %>%
    filter(value > 0) %>% 
    group_by(cell_id, year) %>%
    arrange(desc(value)) %>%
    slice_max(value, n = 1, with_ties = FALSE) %>%
    data.table::dcast(cell_id ~ year, value.var = "variable")
  
}