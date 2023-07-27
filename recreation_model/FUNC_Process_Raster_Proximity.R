process_raster_proximity <- function(raster_data, max_distance) {
  # Create a sequence of score values
  #score_values <- paste0(1:10) # original line
  score_values <- unique(getValues(raster_data))
  score_values <- score_values[!is.na(score_values)]

  # Create empty list to store output rasters
  subset_rasters <- list()
  proximity_rasters <- list()

  # Loop over the score values
  for (value in score_values) {
    # Create a subset raster for the current value
    subset_raster <- raster_data
    subset_raster[subset_raster != value] <- NA

    # Add the subset raster to the list
    subset_rasters[[as.character(value)]] <- subset_raster

    # Create the proximity raster
    proximity_raster <- distance(subset_raster, fun = function(x) x > 0, units = "m")

    # Set cells outside the maximum distance to NA
    proximity_raster[proximity_raster > max_distance] <- NA

    # Add the proximity raster to the list
    proximity_rasters[[as.character(value)]] <- proximity_raster
  }

  # Return the proximity rasters
  return(proximity_rasters)
}
