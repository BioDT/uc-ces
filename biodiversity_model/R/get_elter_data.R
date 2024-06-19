get_elter_data <- function(scientificName){
  par_scientificName <- scientificName
  rm(scientificName)
  
  #read all the different processed data sources
  ecn_veg_baseline <- read.csv("inputs/elter_data/ECN_baseline_vegetation/baseline_veg_data_processed.csv",sep = "")
  
  ecn_veg_baseline$rightsHolder <- "elter"
  ecn_veg_baseline$x <- ecn_veg_baseline$decimalLongitude
  ecn_veg_baseline$y <- ecn_veg_baseline$decimalLatitude
  
  species_data <- filter(ecn_veg_baseline, scientificName == par_scientificName)
  species_data
}