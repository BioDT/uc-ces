## script to get a list of species with useable data from GBIF
library(rgbif)


# all of scotland
species <- occ_count(facet="speciesKey",
          gadmGid = "GBR.3_1", # scotland
          coordinateUncertaintyInMeters='0,101', 
          occurrenceStatus = NULL,
          hasCoordinate=TRUE,
          hasGeospatialIssue=FALSE,
          facetLimit = 5000) 

#
View(species)

#roughly cairngorm area
species2 <- occ_count(facet="speciesKey",
                      geometry="POLYGON((-4.38944 56.83695,-3.08142 56.83695,-3.08142 57.32717,-4.38944 57.32717,-4.38944 56.83695))",
                     gadmGid = "GBR.3_1", # scotland
                     coordinateUncertaintyInMeters='0,101', 
                     occurrenceStatus = NULL,
                     hasCoordinate=TRUE,
                     hasGeospatialIssue=FALSE,
                     facetLimit = 5000)

species2$common_name <- ""
species2$sci_name <- ""

species2 <- species2[species2$count>100,]

View(species2)

#get common name
library(httr)
library(jsonlite)

get_common_name <- function(species_key){
  api_url <- paste0("https://api.gbif.org/v1/species/", species_key)
  response <- GET(api_url)
  if (http_type(response) == "application/json") {
    data <- fromJSON(rawToChar(response$content))
  } else {
    stop("Error: Unable to retrieve data.")
  }
  list(common_name = data$vernacularName,
       sci_name = data$species)
  
}

get_common_name(3314213)

for(i in 1:nrow(species2)){
  gcn <- get_common_name(species2$speciesKey[i])
  
  if(!is.null(gcn$common_name)){
    species2$common_name[i] <- gcn$common_name
  } else {
    species2$common_name[i] <- "NA"
  }
  species2$sci_name[i] <- gcn$sci_name
}

View(species2)

write.table(species2,"biodiversity_model/outputs/cairngorms_sp_list.csv", sep = ",",row.names = F)

writeLines(as.character(species2$speciesKey),"taxonIDs.txt")
