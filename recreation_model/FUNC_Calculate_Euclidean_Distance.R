# input is a list of rasters
# output is also a list of rasters
calculate_euclidean_distance <- function(proximity_rasters, alpha = 0.01101, kappa = 5) {
  # Create an empty list to store the output rasters
  euc_dist_rasters <- list()

  # Loop over the proximity rasters
  for (score in names(proximity_rasters)) {
    # Perform the calculation
    euc_dist_rasters[[score]] <- ((kappa + 1) / (kappa + exp(proximity_rasters[[score]] * alpha))) * as.numeric(gsub("^score(\\d+)$", "\\1", score))
  }

  # Return the output rasters
  return(euc_dist_rasters)
}
