get_env_data <- function(){
  #Currently loading a raster file locally but this could be upgraded to any other raster
  env_data <- rast("inputs/env-layers.tif")
  
  env_data_low_res <- aggregate(env_data, fact = 4)
  env_data_low_res
}