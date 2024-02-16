## script to get a list of species with useable data from GBIF
library(rgbif)
library(dplyr)


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
       sci_name = data$species,
       kingdom = data$kingdom,
       phylum = data$phylum,
       class = data$class,
       order = data$order,
       family = data$family,
       genus = data$genus)
}

get_common_name(3314213)

value_or_na <- function(x){if(is.null(x)){
  ""
}else{
  x
}}

for(i in 1:nrow(species2)){
  gcn <- get_common_name(species2$speciesKey[i])
  
  if(!is.null(gcn$common_name)){
    species2$common_name[i] <- gcn$common_name
  } else {
    species2$common_name[i] <- "NA"
  }
  species2$sci_name[i] <- value_or_na(gcn$sci_name)
  
  species2$kingdom[i] <- value_or_na(gcn$kingdom )
  species2$class[i] <- value_or_na(gcn$class)
  species2$phylum[i] <- value_or_na(gcn$phylum )
  species2$order[i] <- value_or_na(gcn$order)
  species2$family[i] <- value_or_na(gcn$family)
  species2$genus[i] <- value_or_na(gcn$genus)
}

View(species2)

species3 <- species2

# append generic groups
#create columns
species3[,c("all","big5","mammals","birds","plants","herptiles","insects")] <- F
species3$all <- T
species3$big5[species3$sci_name %in% c("Sciurus vulgaris","Cervus elaphus")] <- T
species3$mammals[species3$class =="Mammalia"] <- T
species3$birds[species3$class =="Aves"] <- T
species3$plants[species3$kingdom =="Plantae"] <- T
species3$insects[species3$class =="Insecta"] <- T




# get species images
get_image <- function(sci_name){
  api_url <- paste0("https://api.inaturalist.org/v1/taxa?rank_level=10&per_page=1&order=desc&order_by=observations_count&q=", gsub(" ","%20",sci_name))
  response <- GET(api_url)
  out <- if (http_type(response) == "application/json") {
    data <- fromJSON(rawToChar(response$content))
  } else {
    stop("Error: Unable to retrieve data.")
  }
  
  image_url <- data$results$default_photo$medium_url
  
  if(!is.null(image_url)){
    return(image_url)
  } else {
    return("")
  }

}

species3$image_url<-""
for(i in 326:nrow(species3)){
  Sys.sleep(1)
  species3$image_url[i] <- get_image(species3$sci_name[i])
  cat(i)
}


View(species3)

write.table(species3,"biodiversity_model/outputs/cairngorms_sp_list.csv", sep = ",",row.names = F)

writeLines(as.character(species3$speciesKey),"biodiversity_model/inputs/taxonIDs.txt")
















