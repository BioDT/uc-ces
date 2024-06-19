library(dplyr)

## UK Environmental Change Network (ECN) baseline vegetation data: 1991-2000

# How to get data from RI
# Download data from: https://catalogue.ceh.ac.uk/documents/a7b49ac1-24f5-406e-ac8f-3d05fb583e3b
# Place folder a7b49ac1-24f5-406e-ac8f-3d05fb583e3b into this directory 

# Extract the species look-up table from supporting-documents/VB_DATA_STRUCTURE.rtf and export as species_lookup.csv

#set working directory to this folder
setwd("biodiversity_model/inputs/elter_data/ECN_baseline_vegetation")

#read csv
species_lookup <- read.csv("species_lookup.csv",sep = "\t")
names(species_lookup) <- c("species_id","latin_name","brc_concept","scientificName")

#read the real data
veg_data <- read.csv("a7b49ac1-24f5-406e-ac8f-3d05fb583e3b/data/ECN_VB1.csv")
names(veg_data) <- c("site_code","year","plot_id","plot_type","field_name","species_id")

#location from the documentation
#57° 6'58.84"N 
decimalLatitude <- 57.116344 
#3°49'46.98"W
decimalLongitude <- -3.829717


#only cairngorms site
veg_data <- filter(veg_data,site_code == "T12")

#join the species name
veg_data <- left_join(veg_data,species_lookup)

# add a presence value
veg_data$occurrenceStatus <- "PRESENT"

#select columns needed
veg_data <- veg_data %>% select(scientificName,plot_id,year,occurrenceStatus)
veg_data$decimalLatitude <- decimalLatitude
veg_data$decimalLongitude <- decimalLongitude

#export data
write.table(veg_data,'baseline_veg_data_processed.csv',row.names = F)





