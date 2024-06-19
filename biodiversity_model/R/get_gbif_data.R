get_gbif_data <- function(taxonKey){

  #get the GBIF data from the API
  gbif_data <- rgbif::occ_data(taxonKey = taxonKey,
                        gadmGid = "GBR.3_1", # scotland
                        limit=10000,
                        coordinateUncertaintyInMeters='0,101',
                        occurrenceStatus = NULL,
                        hasCoordinate=TRUE,
                        hasGeospatialIssue=FALSE)
  
  #get the appropriate columns
  gbif_data <- gbif_data$data %>% select(key, 
                                         scientificName, 
                                         y = decimalLatitude,
                                         x = decimalLongitude,
                                         occurrenceStatus,
                                         datasetKey,
                                         publishingOrgKey,
                                         coordinateUncertaintyInMeters,
                                         year,
                                         month,
                                         day,
                                         license,
                                         recordedBy,
                                         identifiedBy,
                                         rightsHolder
  )
  #set presence absence
  gbif_data$pr_ab <- 0
  gbif_data$pr_ab[gbif_data$occurrenceStatus == "PRESENT"] <- 1
  
  gbif_data
}