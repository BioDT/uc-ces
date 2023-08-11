# input is a list of rasters
# output is a raster
normalise_rasters <- function(raster_list, reference_raster) {
  for (raster in raster_list) {
    # set the CRS and Resample the raster to match the resolution of the mask
	if (is.na(projection(raster))) {
	  projection(raster) <- crs(reference_raster)
	} else {
	  raster <- projectRaster(raster, reference_raster)
	}
    raster <- resample(raster, reference_raster, method = "bilinear")

    # Add the raster values to the reference raster
    reference_raster <- sum(reference_raster, raster, na.rm = TRUE)
  }

  # Normalize the reference raster to a scale of 0-1
  reference_raster <- (reference_raster - min(reference_raster[], na.rm = TRUE)) /
    (max(reference_raster[], na.rm = TRUE) - min(reference_raster[], na.rm = TRUE))

  return(reference_raster)
}
