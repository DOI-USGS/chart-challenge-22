scrape_table <- function(file_out, url){
  wss <- read_html(url)
  
  wss_table <- wss %>% 
    html_element('table')
  
  # clean table header
  wss_th <- wss_table %>%
    html_elements("th") %>%
    html_text2() %>% 
    unique() %>% 
    str_replace(pattern = '\n', replacement = ' ') %>% 
    str_replace(pattern = 'square miles', replacement = 'mi2') %>% 
    str_replace(pattern = 'square kilometers', replacement = 'km2') %>% 
    str_replace_all(pattern = ' ', replacement = '_') %>% 
    str_replace(pattern = ',', replacement = '') %>%
    tolower()
  
  wss_body <- wss_table %>%
    html_table() 
  colnames(wss_body) <- wss_th
  
  write_csv(wss_body, file_out)
  return(file_out)

}
prep_data <- function(states, state_file){
  
  # add state abbrev to label axis later
  state_fips <- maps::state.fips %>% 
    distinct(fips, abb) %>%
    mutate(state_cd = str_pad(fips, 2, "left", pad = "0"))  
  
  states %>%
    left_join(read_csv(state_file), by = c('NAME' = 'state')) %>% 
    left_join(state_fips, by = c('GEOID' = 'state_cd')) %>% 
    transform(coastal_km2 = as.numeric(gsub(',', '', coastal_km2))) %>%
    replace_na(list(coastal_km2 = 0)) %>%
    mutate(inland_perc = inland_km2/total_area_km2,
           coastal_perc = coastal_km2/total_area_km2,
           percent_area_water = as.numeric(str_replace(percent_area_water, "%", ""))) %>% 
    select(geometry, inland_perc, total_area_km2, abb)
}
transition_states <- function(state_data, carto_data){
  state_data %>% 
    mutate(id = '% water') %>%
    bind_rows(carto_data %>% mutate(id = 'total area')) %>%
    transform(trans_state = factor(id, ordered = TRUE, levels = c('total area','% water')))
}
