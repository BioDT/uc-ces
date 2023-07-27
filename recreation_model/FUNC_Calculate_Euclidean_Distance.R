calculate_euclidean_distance <- function(proximity_rasters, alpha = 0.01101, kappa = 5) {
  # Create an empty list to store the output rasters
  euc_dist_rasters <- list()

  # Loop over the proximity rasters
  for (score in names(proximity_rasters)) {
    # Get the proximity raster
    proximity_raster <- proximity_rasters[[score]]

    # Perform the calculation
    calc_raster <- ((kappa + 1) / (kappa + exp(proximity_raster * alpha))) * as.numeric(gsub("^score(\\d+)$", "\\1", score))

    # Add the output raster to the list
    euc_dist_rasters[[score]] <- calc_raster
  }

  # Return the output rasters
  return(euc_dist_rasters)
}
