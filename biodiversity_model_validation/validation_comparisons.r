# Load required libraries
library(tidyr)
library(dplyr)
library(readr)
library(sf)
library(raster)
library(lubridate)
library(pROC)
library(leaflet)
library(spdep)

# Load data
species_data = read.csv("p drive data/Vegetation/extracted_data/species_data.csv")
plot_placements = read.csv("p drive data/Vegetation/extracted_data/plot_placements.csv")

# Preview the data
head(species_data)
head(plot_placements)

# Standardise column names in species_data to lowercase
colnames(species_data) <- tolower(colnames(species_data))

# Record whether the species is present in any of the cells within each plot
species_data <- species_data %>%
distinct(plot_id, year, species_name)  %>%
mutate(count = 1)

# Create all combinations of plot, year, and species for absence generation
all_combinations <- expand.grid(
  plot_id = unique(species_data$plot_id),
  year = unique(species_data$year),
  species_name = unique(species_data$species_name)
)

# Merge all_combinations with species_data to generate absences for missing combinations
species_data_absences <- left_join(all_combinations, species_data, 
                                   by = c("plot_id", "year", "species_name")) %>%
  mutate(count = ifelse(is.na(count), 0, 1))  %>%
  filter(year == 2020) # take only the most recent data

# Rename columns in plot_placements and remove duplicate rows
plot_placements = rename(plot_placements, plot_id = Plot) %>%
  distinct()

# Convert plot_placements to spatial data with EPSG:27700 coordinate system
coordinates(plot_placements) <- ~x_easting + y_northing
proj4string(plot_placements) <- CRS("+init=epsg:27700")

# Transform plot_placements to latitude/longitude (EPSG:4326) and convert to dataframe
plot_placements_latlon <- spTransform(plot_placements, CRS("+init=epsg:4326"))
plot_placements_latlon_df <- as.data.frame(plot_placements_latlon)

# Merge transformed plot placements with species_data_absences, including latitude and longitude
data_merged <- plot_placements_latlon_df %>%
  mutate(latitude = coordinates(plot_placements_latlon)[,2],
         longitude = coordinates(plot_placements_latlon)[,1]) %>%
  dplyr::select(-c(coords.x1, coords.x2)) %>%
  right_join(species_data_absences) %>%
  filter(!is.na(latitude), !is.na(longitude))

# Load Cairngorms boundary shapefile
boundary_path <- "cairngorms_boundary/SG_CairngormsNationalPark_2010.shp"
cairngorms_boundary <- st_read(boundary_path)

# Convert data_merged to an sf object (spatial data)
data_merged_sf <- data_merged %>%
  st_as_sf(coords = c("longitude", "latitude"), crs = 4326)  # CRS WGS84 (latitude/longitude)

# Transform the Cairngorms boundary CRS to WGS84 if needed
cairngorms_boundary <- st_transform(cairngorms_boundary, crs = 4326)

# Perform spatial join to retain data within the Cairngorms boundary
data_cairngorms <- st_join(data_merged_sf, cairngorms_boundary, join = st_within)

# Extract latitude and longitude from geometry for final dataframe
data_cairngorms <- data_cairngorms %>%
  mutate(longitude = st_coordinates(.)[, 1],  # Longitude
         latitude = st_coordinates(.)[, 2]) %>%   # Latitude
  dplyr::select(plot_id, species_name, count, latitude, longitude) %>%
  st_drop_geometry()

# Standardise species column by replacing dots with spaces
data_cairngorms$species = gsub("\\.", " ", data_cairngorms$species)

# Get modelled species from tiff files based on filename patterns
modelled_species = gsub(".*prediction_([0-9]+)_.*", "\\1", basename(list.files("ces_data/sdms")))

# Load species model list and filter by modelled species
species_modelled = read.csv("ces_data/cairngorms_sp_list.csv") %>%
  filter(speciesKey %in% modelled_species)

# Match species in modelled data with those in data_cairngorms and subset
species_intersect_keys = species_modelled %>% filter(sci_name %in% data_cairngorms$species) %>%
  distinct() %>% dplyr::select(sci_name, speciesKey)

# Join the species intersection keys with data_cairngorms and filter by modelled species
data_cairngorms = data_cairngorms %>% left_join(species_intersect_keys, join_by(species == sci_name)) %>%
  filter(!is.na(speciesKey))

# Iterate over modelled species keys, process raster and survey data, and compare SDM predictions
for (i in 1:nrow(species_intersect_keys)){
  
  key = species_intersect_keys[i, 2]
  
  print(paste("processing", species_intersect_keys[i, 1]))
  
  # Load SDM prediction raster file
  species_model_tiff = file.path("ces_data/sdms", paste0("prediction_", key, "_2024-02-20.tif"))
  sdm_raster <- raster(species_model_tiff)
  
  # Subset survey data for current species
  ecn_survey_plot_data <- data_cairngorms %>%
    filter(speciesKey == key) %>%
    distinct(plot_id, latitude, longitude, .keep_all = TRUE)
  
  # Extract SDM prediction values for coordinates
  coords <- ecn_survey_plot_data %>% dplyr::select(longitude, latitude)
  sdm_values <- raster::extract(sdm_raster, as.matrix(coords))
  
  # Add SDM predictions to survey data
  ecn_survey_sdm_compare <- ecn_survey_plot_data %>%
    mutate(sdm_prediction = sdm_values) %>%
    filter(!is.na(date))
  
  # Bind results for each species into one dataframe
  if (i == 1){
    ecn_survey_sdm_compare_all <- ecn_survey_sdm_compare
  } else{
    ecn_survey_sdm_compare_all <- rbind(ecn_survey_sdm_compare_all, ecn_survey_sdm_compare)
  }
  
}

# Filter for a specific species and calculate the mean of SDM predictions
ecn_survey_sdm_compare_all %>%
  filter(species_name == "Agrostis capillaris") %>%
  pull(sdm_prediction) %>%
  mean()

# Plot mean count and SDM predictions for each species
library(ggplot2)

# Calculate mean count per species
mean_counts <- ecn_survey_sdm_compare_all %>%
  group_by(species_name) %>%
  summarise(mean_count = mean(count))

# Create a combined plot with mean counts and SDM prediction boxplots
p <- ggplot() +
  geom_point(
    data = mean_counts, 
    aes(x = species_name, y = mean_count, color = "Count"), 
    shape = 4, 
    size = 5,  # Size of cross
    stroke = 2  # Stroke width
  ) +
  geom_boxplot(
    data = ecn_survey_sdm_compare_all, 
    aes(x = species_name, y = sdm_prediction, fill = "Prediction"),
    alpha = 0.4,
    outlier.shape = NA
  ) +
  labs(x = "Species", y = "Mean Count", fill = "Measure", color = "Measure") +
  scale_fill_manual(values = c("Prediction" = "red")) +
  scale_color_manual(values = c("Count" = "blue")) +
  scale_y_continuous(
    name = "Proportion of sites present",
    sec.axis = sec_axis(~ ., name = "SDM Prediction")
  ) +
  theme_classic() +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 1, size = 10),
    axis.text.y = element_text(size = 10),
    axis.title.x = element_text(size = 15),
    axis.title.y = element_text(size = 15),
    legend.position = "top"
  )

# Display the plot
p

# Calculate mean count, SDM prediction, and their difference per species
mean_count_diff <- ecn_survey_sdm_compare_all %>%
  group_by(species_name) %>%
  summarise(mean_count = mean(count),
            mean_pred = mean(sdm_prediction)) %>%
  mutate(prediction_diff = mean_pred - mean_count) %>%
  arrange(desc(prediction_diff)) %>%
  mutate(species_name = factor(species_name, levels = species_name))

# Plot prediction differences for each species
diff_plot <- ggplot(mean_count_diff, aes(y = species_name, x = prediction_diff)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray") +
  geom_segment(aes(y = species_name, yend = species_name, x = 0, xend = prediction_diff), color = "gray") +
  geom_point(
    aes(y = species_name, x = prediction_diff, color = "Count"), 
    shape = 4, 
    size = 5,  
    stroke = 2  
  ) +
  labs(
    y = "Species", 
    x = "Difference (mean SDM prediction - proportion of sites present)"
  ) +
  theme_classic() +
  theme(
    axis.text.y = element_text(size = 10),
    axis.title.x = element_text(size = 15),
    axis.title.y = element_text(size = 15),
    legend.position = "none"
  )

# Display the difference plot
diff_plot

# Create ROC curve for SDM predictions and calculate AUC
roc_curve <- roc(ecn_survey_sdm_compare_all$count, ecn_survey_sdm_compare_all$sdm_prediction)

# Plot the ROC curve
plot(roc_curve)

# Calculate and display AUC
auc(roc_curve)

# Calculate MSE between observed counts and SDM predictions
mse <- mean((ecn_survey_sdm_compare_all$count - ecn_survey_sdm_compare_all$sdm_prediction)^2)
print(paste("Mean Squared Error (MSE):", mse))
# Calculate residuals
ecn_survey_sdm_compare_all <- ecn_survey_sdm_compare_all %>%
  mutate(residual = count - sdm_prediction)

# Convert dataframe to spatial object
ecn_sf <- st_as_sf(ecn_survey_sdm_compare_all, coords = c("longitude", "latitude"), crs = 4326)

####################

# Load required libraries
library(sf)
library(reshape2)

# Calculate the pairwise distance matrix (distances in meters)
distance_matrix <- st_distance(ecn_sf)

# Convert the distance matrix to a numeric matrix, removing units
distance_matrix_numeric <- as.numeric(distance_matrix)
dim(distance_matrix_numeric) <- dim(distance_matrix)  # Retain the original dimensions

# Convert distance matrix to a data frame for easier analysis
distance_df <- as.data.frame(distance_matrix_numeric)

# Reshape the distance matrix to a long format to visualize all pairwise distances
distance_long <- melt(distance_df, varnames = c("Point1", "Point2"), value.name = "Distance")

# Filter out zero distances (distance of a point to itself)
distance_long <- distance_long[distance_long$Distance > 0, ]

# Convert distances from meters to kilometers
distance_long$Distance_km <- distance_long$Distance / 1000

# Summarize the distribution of distances
summary(distance_long$Distance_km)

####################

# Create a neighbourhood list for spatial weighting
coords <- st_coordinates(ecn_sf)
neighbours <- dnearneigh(coords, 0, 5)  # 0-5 km range for neighbouring points (adjust as necessary)
weights <- nb2listw(neighbours, style = "W")

# Calculate Moran's I
moran_test <- moran.test(ecn_sf$residual, listw = weights)
print(moran_test) # Randomness with no clear spatial correlation

# # Create a colour palette for the residuals
# pal <- colorNumeric(palette = "RdYlBu", domain = ecn_survey_sdm_compare_all$residual)

# # Plot residuals on a leaflet map
# leaflet(ecn_survey_sdm_compare_all) %>%
#   addTiles() %>%
#   addCircleMarkers(
#     ~longitude, ~latitude,
#     color = ~pal(residual),
#     radius = 5,
#     stroke = FALSE,
#     fillOpacity = 0.8,
#     popup = ~paste("Plot ID:", plot_id, "<br>",
#                    "Species:", species_name, "<br>",
#                    "Year:", year, "<br>",
#                    "Observed Count:", count, "<br>",
#                    "SDM Prediction:", sdm_prediction, "<br>",
#                    "Residual:", residual)
#   ) %>%
#   addLegend("bottomright", pal = pal, values = ~residual,
#             title = "Residual (Count - Prediction)",
#             opacity = 1)

# Stats for report

# Obtain year range and unique plot locations
range(data_cairngorms$year, na.rm = TRUE)
length(unique(data_cairngorms$plot_id))

length(unique(species_data$species_name))

names(species_data)

# citations

write_citation_to_bib <- function(package_name) {

  # Get the citation for the package
  package_citation <- citation(package_name)
  
  # Convert the citation to BibTeX format
  bib_entry <- toBibtex(package_citation)

  # compile the reference path
  ref_path = file.path("references", paste0(package_name, ".bib"))
  
  # Write the BibTeX entry to the specified .bib file
  writeLines(bib_entry, ref_path)
  
  message(paste("Citation for package", package_name, "written to", ref_path))
}

# Usage example
write_citation_to_bib("raster")
write_citation_to_bib("sp")
write_citation_to_bib("sf")
write_citation_to_bib("dplyr")
write_citation_to_bib("pROC")
write_citation_to_bib("spdep")















