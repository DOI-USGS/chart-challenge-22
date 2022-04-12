create_event_swarm <- function(event_data, metadata, start_period, end_period, target_threshold){
  event_subset <- event_data %>% 
    left_join(metadata, by = "StaID", suffix = c("",".gages")) %>% 
    filter(HUC02 == 14) %>% # restrict to upper Colorado river basin
    filter(start > start_period) %>%
    filter(end <= end_period) %>% 
    filter(threshold == target_threshold) %>% 
    mutate(onset_day = as.integer(start - start_period)) %>% 
    mutate(end_day = as.integer(end - start_period)) %>% 
    arrange(onset_day, drought_id)
  
  # set up an empty "swarm grid" to place drought events into
  n <- 100 # set arbitrarily large number of possible simultaneous drought events positions. Trimmed prior to plotting
  
  E <- as_tibble(matrix(NaN,nrow=n,ncol=max(event_subset$end_day)+1))
  E <- E %>% mutate(priority = 1:n)
  E <- E %>% arrange(desc(priority)) %>% 
    bind_rows(E) %>% 
    mutate(rnum = 1:(2*n))
  
  # loop through each event and place into best available spot in grid
  for (idx in 1:nrow(event_subset)){
    temp_dur <- event_subset[[idx,'duration']]
    temp_startd <-event_subset[[idx,'onset_day']]
    # find available spots looking within 1 day +/- the start date (to encourage a little compactness)
    avail_rows <- E %>% select(all_of(temp_startd:(temp_startd + temp_dur - 1)),priority,rnum) %>% 
      filter(is.na(if_all(starts_with("V")))) %>% 
      mutate(pos = 0)
    avail_rows_plus1d <- E %>% select(all_of((temp_startd+1):(temp_startd + temp_dur)),priority,rnum) %>%
      filter(is.na(if_all(starts_with("V")))) %>%
      mutate(pos = 1)
    avail_rows_minus1d <- E %>% select(all_of((temp_startd-1):(temp_startd + temp_dur - 2)),priority,rnum) %>%
      filter(is.na(if_all(starts_with("V")))) %>%
      mutate(pos = -1)
    # find spot closest to central axis
    all_avail_rows <- bind_rows(avail_rows, avail_rows_minus1d, avail_rows_plus1d) %>% 
      arrange(priority) %>%
      group_by(priority) %>%
      slice_sample(prop = 1) %>% # adds a little randomness by assigning to spot above or below central axis randomly
      ungroup()
    temp_rnum <- all_avail_rows[[1,'rnum']]
    temp_pos_key <- all_avail_rows[[1, 'pos']]
    if (temp_startd == 1){
      temp_pos_key <- 0
    }
    # assign event to identified spot by using duration value
    E[temp_rnum,((temp_startd + temp_pos_key):(temp_startd + temp_dur - 1 + temp_pos_key))] <- event_subset[[idx,'duration']]
    E[temp_rnum,(temp_startd + temp_dur + temp_pos_key)] <- 0 # enforces a space between subsequent events
  }
  # trim unused rows
  ind <- E %>% select(-priority,-rnum) %>% 
    apply( 1, function(x) all(is.na(x)))
  E <-E[ !ind, ]
  
  E[E == 0] = NaN # remove spaces added to avoid events appearing connected
  
  ncols = ncol(E)-2
  
  E <- mutate(E, decade = as.factor(floor(year(start_period)/10)*10))
  
  plot_dat <- E %>% select(-priority) %>% 
    pivot_longer(cols=1:ncols, names_to = "names", values_to = "duration")
  plot_dat$names<- str_remove(plot_dat$names,"V")
  plot_dat <- plot_dat %>% mutate(dt = as.integer(names)) %>% 
    mutate(date = as.Date(start_period + dt - 1)) %>% 
    mutate(rnum = rnum - n) %>% 
    drop_na()
  
  return(plot_dat)
}


