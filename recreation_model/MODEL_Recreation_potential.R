#################################################
### SETUP THE ENVIRONMENT AND COMMON FEATURES ###
#################################################


# Set the base workding directory
setwd("data")

#load libraries
library(raster) # possible only needs raster and not rgdal and terra
library(rgdal)
library(terra)
library(tools)

# call any functions to the environment
source("FUNC_Raster_Reclassifier.R")
source("FUNC_Process_Raster_Proximity.R")
source("FUNC_Calculate_Euclidean_Distance.R")

# IMPORTANT - SET THE NAME OF THE SCORE COLUMN TO BE USED throughout. (E.G. SR FOR Soft Recreation)
Score_column <- "SR"  # Replace with the actual column name for reclassification

# load in the shapefile mask
mask <- shapefile("boundaries.shp")

# import empty raster for resolution
Raster_Empty <- raster("empty.tif")

# Set the common CRS (GB grid) using the empty raster
common_crs <- crs(Raster_Empty)

# Used to set the extent and resolution of the new raster to match the existing raster
Raster_Blank <- raster(extent(Raster_Empty), res = res(Raster_Empty), crs = crs(Raster_Empty))

##############################################
### COMPONENT 1 - COMPUTE NORMALIZED SLSRA ###
##############################################

# firstly reclassify the unscored rasters with the correct score using the function: FUNC_Raster_Reclassifier
# Set the folder paths here
raster_folder <- "SLSRA/Pre_Scored_Rasters"
csv_folder <- "SLSRA/Table_Values"
Score_column <- "HR"  # Replace with the actual column name for reclassification
output_folder <- "SLSRA/Scored_Rasters"  # Set the desired output folder
component_folder_SLSRA <- "SLSRA/Component_Output/"

# Call the function to reclassify rasters by score
modified_rasters <- reclassify_rasters(raster_folder, csv_folder, Score_column, output_folder)
#print(modified_rasters)
#plot(modified_rasters$Scored_SLSRA_HLUA_SR.tif) # example of viewing one of the outputs

# Set the SLSRA folder path containing the rasters
scored_raster_folder <- output_folder

# Get the list SLSRA component rasters located in the folder SLSRA folder
raster_files <- list.files(scored_raster_folder, pattern = ".tif$", full.names = TRUE)

# Filter the raster files based on the two-letter code in Score_column
raster_files <- raster_files[grepl(paste0(Score_column, ".tif$"), basename(raster_files))]

# Initialize an empty raster to store the sum
sum_raster <- Raster_Empty
values(sum_raster) <- 0

# Loop through each raster file
for (file in raster_files) {
  # Read the raster and set the CRS
  raster <- raster(file)
  raster <- projectRaster(raster, crs = common_crs)

  # Resample the raster to match the resolution of the mask
  raster <- resample(raster, sum_raster, method = "bilinear")

  # Add the raster values to the sum raster
  sum_raster <- sum_raster + raster
}

# Normalize the sum raster to a scale of 0-1
SLSRA_Norm <- (sum_raster - min(sum_raster[], na.rm = TRUE)) /
  (max(sum_raster[], na.rm = TRUE) - min(sum_raster[], na.rm = TRUE))

# visualise the output map
plot(SLSRA_Norm, main = "Normalized SLSRA")
print(SLSRA_Norm)

# Write the output raster
writeRaster(SLSRA_Norm, paste0("SLSRA/Component_Output/SLSRA_Norm_", Score_column), format = "GTiff", overwrite = TRUE)

###############################################

###############################################
### COMPONENT 2 - COMPUTE NORMALIZED FIPS_N ###
###############################################

# firstly reclassify the un-scored rasters with the correct score using the function: FUNC_Raster_Reclassifier
# Set the folder paths here
raster_folder <- "FIPS_N/Pre_Scored_Rasters"
csv_folder <- "FIPS_N/Table_Values"
output_folder <- "FIPS_N/Scored_Rasters"  # Set the desired output folder
component_folder_FIPS_N <- "FIPS_N/Component_Output/"

# Call the function to reclassify rasters by score
modified_rasters <- reclassify_rasters(raster_folder, csv_folder, Score_column, output_folder)
#print(modified_rasters)
#plot(modified_rasters$Scored_SLSRA_HLUA_SR.tif) # example of viewing one of the outputs

####

# Slope needs to be dealt with differently due to grouped output having issues in main function.
# Step 1 - Function to add a user-defined column to the slope_df dataframe
add_column_to_slope_df <- function(Score_column, Scores_FIPS_N_Slope) {
  slope_df[[Score_column]] <- Scores_FIPS_N_Slope[[Score_column]]
  return(slope_df)
}

# Step 2 - Create the slope_df dataframe which uses the slope classes in the paper
slope_df <- data.frame(
  group_val_min = c(0, 1.72, 2.86, 5.71, 11.31, 16.7),
  group_val_max = c(1.72, 2.86, 5.71, 11.31, 16.7, Inf)
)


# Step 3 - Load the existing slope csv and raster
Scores_FIPS_N_Slope <- read.csv("FIPS_N/Slope/Table_Values/Scores_FIPS_N_Slope.csv")
Slope_Raster <- raster("FIPS_N/Slope/Pre_Scored_Rasters/Raster_FIPS_N_Slope.tif")

# Step 4 - Call the function to add the user-defined column to the slope_df dataframe
slope_df <- add_column_to_slope_df(Score_column, Scores_FIPS_N_Slope)

# Step 5 - Convert table to a matrix
reclass_m <- data.matrix(slope_df)

# Step 6 - reclassify raster
Slope_Raster_classified <- reclassify(Slope_Raster,
                             reclass_m)

# Step 7 - Create the output file path with Score_column name
output_file <- file.path(output_folder, paste0("Scored_Scores_FIPS_N_Slope", "_", Score_column, ".tif"))

# Step 8 - Write the output raster
writeRaster(Slope_Raster_classified, output_file, format = "GTiff", overwrite = TRUE)

####

# Set the FIPS_N folder path containing the rasters
scored_raster_folder <- output_folder

# Get the list FIPS_N component rasters located in the folder FIPS_N folder
raster_files <- list.files(scored_raster_folder, pattern = ".tif$", full.names = TRUE)

# Filter the raster files based on the two-letter code in Score_column
raster_files <- raster_files[grepl(paste0(Score_column, ".tif$"), basename(raster_files))]

# Initialize an empty raster to store the sum
sum_raster <- Raster_Empty
values(sum_raster) <- 0

# Loop through the raster files
for (file in raster_files) {
  # Read the raster
  raster <- raster(file)

  # Check if the raster has a valid projection
  if (is.na(projection(raster))) {
    # Assign the common CRS to the raster
    projection(raster) <- common_crs
  } else {
    # Reproject the raster to the common CRS
    raster <- projectRaster(raster, crs = common_crs)
  }

  # Resample the raster to match the resolution of the mask
  raster <- resample(raster, sum_raster, method = "bilinear")

  # Add the raster values to the sum raster
  sum_raster <- sum_raster + raster
}

# Normalize the sum raster to a scale of 0-1
FIPS_N_Norm <- (sum_raster - min(sum_raster[], na.rm = TRUE)) /
  (max(sum_raster[], na.rm = TRUE) - min(sum_raster[], na.rm = TRUE))

# visualise the output map
plot(FIPS_N_Norm, main = "Normalized FIPS_N")
print(FIPS_N_Norm)

# Write the output raster
writeRaster(FIPS_N_Norm, paste0("FIPS_N/Component_Output/FIPS_N_Norm_", Score_column), format = "GTiff", overwrite = TRUE)


###############################################

###############################################
### COMPONENT 3 - COMPUTE NORMALIZED FIPS_I ###
###############################################

# firstly reclassify the un-scored rasters with the correct score using the function: FUNC_Raster_Reclassifier
# Set the folder paths here
raster_folder <- "FIPS_I/Pre_Scored_Rasters"
csv_folder <- "FIPS_I/Table_Values"
output_folder <- "FIPS_I/Scored_Rasters"  # Set the desired output folder
component_folder_FIPS_I <- "FIPS_I/Component_Output/"

# Call the function to reclassify rasters by score
modified_rasters <- reclassify_rasters(raster_folder, csv_folder, Score_column, output_folder)
#print(modified_rasters)
#plot(modified_rasters$Scored_FIPS_I_NFERA_SR.tif) # example of viewing one of the outputs

####

# secondly calculate the proximity of values within each rasters out to a set limit of.... 1500m?
# List all files in the raster folder
raster_files <- list.files(output_folder, full.names = TRUE)

# Filter the raster files based on the two-letter code in Score_column
raster_files <- raster_files[grepl(paste0(Score_column, ".tif$"), basename(raster_files))]

# Set maximum distance for the proximity in meters.  Is 1500 correct??
max_distance <- 1500

# Create an empty list to hold the proximity rasters
all_proximity_rasters <- list()

# Loop through each raster file
for (file in raster_files) {
  # Read the raster
  raster <- raster(file)

  # Call the process_raster_proximity function
  proximity_raster <- process_raster_proximity(raster, max_distance)

  # Get the filename without the filepath
  filename_FIPS_I <- file_path_sans_ext(basename(file))

  # Add the proximity raster to the list with the filename as the key
  all_proximity_rasters[[filename_FIPS_I]] <- proximity_raster
}

#print(all_proximity_rasters)
#plot(all_proximity_rasters$Scored_FIPS_I_NFERR_HR[[7]])

# Create the raster name with the last two letters set using the "Score_column" value
#this is for calling the correct files during the euc distance where SR and HR (or other) might be present
raster_name_NFERA <- paste0("Scored_FIPS_I_NFERA_", Score_column)
raster_name_NFERR <- paste0("Scored_FIPS_I_NFERR_", Score_column)
raster_name_NFERP <- paste0("Scored_FIPS_I_NFERP_", Score_column)
raster_name_Walks <- paste0("Scored_FIPS_I_Walks_", Score_column)


####

# Thirdly convert proximity to euclidean distance based on score.
# Calculate Euclidean distances for NFERA raster
euc_dist_rasters_NFERA <- calculate_euclidean_distance(all_proximity_rasters[[raster_name_NFERA]])
# Iterate over each raster in the list and set extent and resolution
for (i in seq_along(euc_dist_rasters_NFERA)) {
  euc_dist_rasters_NFERA[[i]] <- projectRaster(euc_dist_rasters_NFERA[[i]], Raster_Blank)
}
#print(euc_dist_rasters_NFERA)
#plot(euc_dist_rasters_NFERA[["7"]])

# Calculate Euclidean distances for NFERR raster
euc_dist_rasters_NFERR <- calculate_euclidean_distance(all_proximity_rasters[[raster_name_NFERR]])
# Iterate over each raster in the list and set extent and resolution
for (i in seq_along(euc_dist_rasters_NFERR)) {
  euc_dist_rasters_NFERR[[i]] <- projectRaster(euc_dist_rasters_NFERR[[i]], Raster_Blank)
}
#print(euc_dist_rasters_NFERR)
#plot(euc_dist_rasters_NFERR[["5"]])

# Calculate Euclidean distances for NFERP raster
euc_dist_rasters_NFERP <- calculate_euclidean_distance(all_proximity_rasters[[raster_name_NFERP]])
# Iterate over each raster in the list and set extent and resolution
for (i in seq_along(euc_dist_rasters_NFERP)) {
  euc_dist_rasters_NFERP[[i]] <- projectRaster(euc_dist_rasters_NFERP[[i]], Raster_Blank)
}
#print(euc_dist_rasters_NFERP)
#plot(euc_dist_rasters_NFERP[["1"]])

# Calculate Euclidean distances for Walks raster
euc_dist_rasters_Walks <- calculate_euclidean_distance(all_proximity_rasters[[raster_name_Walks]])
# Iterate over each raster in the list and set extent and resolution
for (i in seq_along(euc_dist_rasters_Walks)) {
  euc_dist_rasters_Walks[[i]] <- projectRaster(euc_dist_rasters_Walks[[i]], Raster_Blank)
}
#print(euc_dist_rasters_Walks)
#plot(euc_dist_rasters_Walks[["9"]])



####

#plot(FIPS_I_NFERA_sum)
#print(FIPS_I_NFERA_sum)

# Create an empty raster to store the sum
FIPS_I_NFERA_sum <- Raster_Blank
values(FIPS_I_NFERA_sum) <- 0

# Loop over the output rasters for NFERA
for (raster_score in euc_dist_rasters_NFERA) {
  FIPS_I_NFERA_sum <- sum(FIPS_I_NFERA_sum, raster_score, na.rm = TRUE)
}

# Normalize the sum raster to a scale of 0-1
FIPS_I_NFERA_norm <- (FIPS_I_NFERA_sum - min(FIPS_I_NFERA_sum[], na.rm = TRUE)) /
  (max(FIPS_I_NFERA_sum[], na.rm = TRUE) - min(FIPS_I_NFERA_sum[], na.rm = TRUE))

# Clip the sum raster by the shapefile
FIPS_I_NFERA_norm <- mask(FIPS_I_NFERA_norm, mask)

plot(FIPS_I_NFERA_norm)

####

# Create an empty raster to store the sum
FIPS_I_NFERR_sum <- Raster_Blank
values(FIPS_I_NFERR_sum) <- 0

# Loop over the output rasters for NFERR
for (raster_score in euc_dist_rasters_NFERR) {
  FIPS_I_NFERR_sum <- sum(FIPS_I_NFERR_sum, raster_score, na.rm = TRUE)
}

# Normalize the sum raster to a scale of 0-1
FIPS_I_NFERR_norm <- (FIPS_I_NFERR_sum - min(FIPS_I_NFERR_sum[], na.rm = TRUE)) /
  (max(FIPS_I_NFERR_sum[], na.rm = TRUE) - min(FIPS_I_NFERR_sum[], na.rm = TRUE))

# Clip the sum raster by the shapefile
FIPS_I_NFERR_norm <- mask(FIPS_I_NFERR_norm, mask)

plot(FIPS_I_NFERR_norm)


####

# Create an empty raster to store the sum
FIPS_I_Walks_sum <- Raster_Blank
values(FIPS_I_Walks_sum) <- 0

# Loop over the output rasters for walks
for (raster_score in euc_dist_rasters_Walks) {
  FIPS_I_Walks_sum <- sum(FIPS_I_Walks_sum, raster_score, na.rm = TRUE)
}

# Normalize the sum raster to a scale of 0-1
FIPS_I_Walks_norm <- (FIPS_I_Walks_sum - min(FIPS_I_Walks_sum[], na.rm = TRUE)) /
  (max(FIPS_I_Walks_sum[], na.rm = TRUE) - min(FIPS_I_Walks_sum[], na.rm = TRUE))

# Clip the sum raster by the shapefile
FIPS_I_Walks_norm <- mask(FIPS_I_Walks_norm, mask)

plot(FIPS_I_Walks_norm)

####

# Create an empty raster to store the sum
FIPS_I_NFERP_sum <- Raster_Blank
values(FIPS_I_NFERP_sum) <- 0

# Loop over the output rasters for NFERP
for (raster_score in euc_dist_rasters_NFERP) {
  FIPS_I_NFERP_sum <- sum(FIPS_I_NFERP_sum, raster_score, na.rm = TRUE)
}

# Normalize the sum raster to a scale of 0-1
FIPS_I_NFERP_norm <- (FIPS_I_NFERP_sum - min(FIPS_I_NFERP_sum[], na.rm = TRUE)) /
  (max(FIPS_I_NFERP_sum[], na.rm = TRUE) - min(FIPS_I_NFERP_sum[], na.rm = TRUE))

# Clip the sum raster by the shapefile
FIPS_I_NFERP_norm <- mask(FIPS_I_NFERP_norm, mask)

plot(FIPS_I_NFERP_norm)

####

# Add together rasters
FIPS_I <- FIPS_I_NFERA_norm + FIPS_I_NFERR_norm + FIPS_I_Walks_norm + FIPS_I_NFERP_norm
plot(FIPS_I)

# Normalize the sum raster to a scale of 0-1
FIPS_I_Norm <- (FIPS_I - min(FIPS_I[], na.rm = TRUE)) /
  (max(FIPS_I[], na.rm = TRUE) - min(FIPS_I[], na.rm = TRUE))
plot(FIPS_I_Norm)
#print(FIPS_I_Norm)

writeRaster(FIPS_I_Norm, paste0("FIPS_I/Component_Output/FIPS_I_Norm_", Score_column),
            format = "GTiff", overwrite = TRUE)


###############################################

###############################################
### COMPONENT 4 - COMPUTE NORMALIZED Water ###
###############################################

# firstly reclassify the un-scored rasters with the correct score using the function: FUNC_Raster_Reclassifier
# Set the folder paths here
raster_folder <- "Water/Pre_Scored_Rasters"
csv_folder <- "Water/Table_Values"
output_folder <- "Water/Scored_Rasters"  # Set the desired output folder
component_folder_Water <- "Water/Component_Output/"

# Call the function to reclassify rasters by score
modified_rasters <- reclassify_rasters(raster_folder, csv_folder, Score_column, output_folder)
#print(modified_rasters)
#plot(modified_rasters$Scored_FIPS_I_NFERA_SR.tif) # example of viewing one of the outputs

####

# secondly calculate the proximity of values within each rasters out to a set limit of.... 1500m?
# List all files in the raster folder
raster_files <- list.files(output_folder, full.names = TRUE)

# Filter the raster files based on the two-letter code in Score_column
raster_files <- raster_files[grepl(paste0(Score_column, ".tif$"), basename(raster_files))]

# Set maximum distance for the proximity in meters.  Is 1500 correct??
max_distance <- 1500

# Create an empty list to hold the proximity rasters
all_proximity_rasters <- list()

# Loop through each raster file
for (file in raster_files) {
  # Read the raster
  raster <- raster(file)

  # Call the process_raster_proximity function
  proximity_raster <- process_raster_proximity(raster, max_distance)

  # Get the filename without the filepath
  filename_Water <- file_path_sans_ext(basename(file))

  # Add the proximity raster to the list with the filename as the key
  all_proximity_rasters[[filename_Water]] <- proximity_raster
}

#print(all_proximity_rasters)

# Create the raster name with the last two letters set using the "Score_column" value
#this is for calling the correct files during the euc distance where SR and HR (or other) might be present
raster_name_Rivers <- paste0("Scored_Water_Rivers_", Score_column)
raster_name_Lakes <- paste0("Scored_Water_Lakes_", Score_column)

####

# Thirdly convert proximity to euclidean distance based on score.
# Calculate Euclidean distances for Rivers raster
euc_dist_rasters_Rivers <- calculate_euclidean_distance(all_proximity_rasters[[raster_name_Rivers]])
# Iterate over each raster in the list and set extent and resolution
for (i in seq_along(euc_dist_rasters_Rivers)) {
  euc_dist_rasters_Rivers[[i]] <- projectRaster(euc_dist_rasters_Rivers[[i]], Raster_Blank)
}
#print(euc_dist_rasters_Rivers)
#plot(euc_dist_rasters_Rivers[["10"]])

# Calculate Euclidean distances for Lakes raster
euc_dist_rasters_Lakes <- calculate_euclidean_distance(all_proximity_rasters[[raster_name_Lakes]])
# Iterate over each raster in the list and set extent and resolution
for (i in seq_along(euc_dist_rasters_Lakes)) {
  euc_dist_rasters_Lakes[[i]] <- projectRaster(euc_dist_rasters_Lakes[[i]], Raster_Blank)
}
#print(euc_dist_rasters_Lakes)
#plot(euc_dist_rasters_Lakes[["10"]])

####

# Create an empty raster to store the sum
Water_Rivers_sum <- Raster_Blank
values(Water_Rivers_sum) <- 0

# Loop over the output rasters for Rivers
for (raster_score in euc_dist_rasters_Rivers) {
  Water_Rivers_sum <- sum(Water_Rivers_sum, raster_score, na.rm = TRUE)
}

# Normalize the sum raster to a scale of 0-1
Water_Rivers_norm <- (Water_Rivers_sum - min(Water_Rivers_sum[], na.rm = TRUE)) /
  (max(Water_Rivers_sum[], na.rm = TRUE) - min(Water_Rivers_sum[], na.rm = TRUE))

# Clip the sum raster by the shapefile
Water_Rivers_norm <- mask(Water_Rivers_norm, mask)

plot(Water_Rivers_norm)

####

# Create an empty raster to store the sum
Water_Lakes_sum <- Raster_Blank
values(Water_Lakes_sum) <- 0

# Loop over the output rasters for Lakes
for (raster_score in euc_dist_rasters_Lakes) {
  Water_Lakes_sum <- sum(Water_Lakes_sum, raster_score, na.rm = TRUE)
}

# Normalize the sum raster to a scale of 0-1
Water_Lakes_norm <- (Water_Lakes_sum - min(Water_Lakes_sum[], na.rm = TRUE)) /
  (max(Water_Lakes_sum[], na.rm = TRUE) - min(Water_Lakes_sum[], na.rm = TRUE))

# Clip the sum raster by the shapefile
Water_Lakes_norm <- mask(Water_Lakes_norm, mask)

plot(Water_Lakes_norm)


####

# Add together rasters
Water <- Water_Lakes_norm + Water_Rivers_norm
plot(Water)

# Normalize the sum raster to a scale of 0-1
Water_Norm <- (Water - min(Water[], na.rm = TRUE)) /
  (max(Water[], na.rm = TRUE) - min(Water[], na.rm = TRUE))
plot(Water_Norm)

writeRaster(Water_Norm, paste0("Water/Component_Output/Water_Norm_", Score_column),
            format = "GTiff", overwrite = TRUE)

###############################################

#############################################
### Compute and normailise final RP Model ###
#############################################
# Set output folder
output_folder <- "RP_Output"

# List of folders containing the files
folder_list <- c(component_folder_SLSRA, component_folder_FIPS_N, component_folder_FIPS_I, component_folder_Water)

# Get the list SLSRA component rasters located in the folder SLSRA folder
raster_files <- list.files(folder_list, pattern = ".tif$", full.names = TRUE)

# Filter the raster files based on the two-letter code in Score_column
raster_files <- raster_files[grepl(paste0(Score_column, ".tif$"), basename(raster_files))]

# Initialize an empty raster to store the sum
sum_raster <- Raster_Empty
values(sum_raster) <- 0

# Loop through each raster file
for (file in raster_files) {
  # Read the raster and set the CRS
  raster <- raster(file)
  raster <- projectRaster(raster, crs = common_crs)

  # Resample the raster to match the resolution of the empty raster
  raster <- resample(raster, sum_raster, method = "bilinear")

  # Add the raster values to the sum raster
  sum_raster <- sum_raster + raster
}

# Normalize the sum raster to a scale of 0-1
BioDT_RP_Norm  <- (sum_raster - min(sum_raster[], na.rm = TRUE)) /
  (max(sum_raster[], na.rm = TRUE) - min(sum_raster[], na.rm = TRUE))

#Clip the raster by the mask
BioDT_RP_Norm <- mask(BioDT_RP_Norm, mask)

# visualise the output map
plot(BioDT_RP_Norm, main = "BioDT_RP_Norm ")
print(BioDT_RP_Norm )

# Write the output raster
writeRaster(BioDT_RP_Norm, paste0("RP_Output/BioDT_RP_Norm_", Score_column),
            format = "GTiff", overwrite = TRUE)

####

###############################################

##############################################
### Visualise output - not required to run ###
##############################################


# Load the raster
#raster_file <- BioDT_RP_Norm
raster <- BioDT_RP_Norm

# Calculate quantiles and standard deviation
quantiles <- quantile(raster[], probs = seq(0, 1, by = 1/7), na.rm = TRUE)
sd_min_max <- sd(na.omit(c(minValue(raster), maxValue(raster))))
print(quantiles)

# Define colors for each class
colors <- c("#440154", "#a3478b", "#d76885", "#e6f494", "#5dc74c", "#2f7d26", "#0e610b")

# Reclassify the raster into 7 classes
reclass_raster <- cut(raster, breaks = c(minValue(raster) - 2 * sd_min_max, quantiles, maxValue(raster) + 2 * sd_min_max),
                      include.lowest = TRUE)

# Normalize the sum raster to a scale of 0-1
reclass_raster<- (reclass_raster - min(reclass_raster[], na.rm = TRUE)) /
  (max(reclass_raster[], na.rm = TRUE) - min(reclass_raster[], na.rm = TRUE))

# Plot the cropped raster with quantile colors
plot(cropped_raster, col = colors, legend = FALSE, box = FALSE, axes = FALSE)

# Add the title manually
title(main = "Soft Recreational Potential", line = -2)

# Calculate min and max quantile values
quantile_min_max <- round(quantiles, 2)

# Drop the first part of quantile names
quantile_labels <- paste(quantile_min_max[-length(quantile_min_max)], " - ", quantile_min_max[-1], sep = "")

# Adjust the first and last legend names
quantile_labels[1] <- paste("<", round(max(quantiles[2]),2), sep = " ")  # Set the first legend name to "< max"
quantile_labels[7] <- paste(">", round(max(quantiles[7]),2), sep = " ")

# Drop the first part of quantile names
#quantile_labels <- paste(quantile_min_max[-length(quantile_min_max)], " - ", quantile_min_max[-1], sep = "")

# Calculate the coordinates for the legend
plot_area <- par("usr")
legend_x <- plot_area[1] + 0.00  # Adjust the x position of the legend
legend_y <- plot_area[4] - (1/10) * (plot_area[4] - plot_area[3])  # Adjust the y position of the legend

# Manually position the legend with increased vertical spacing
legend("topleft", legend = quantile_labels, fill = colors, bty = "n", ncol = 2, title = "Recreational Potential",
       xjust = 0, yjust = 1, x.intersp = 0.5, y.intersp = 0.75, x = legend_x, y = legend_y, , cex=0.75)
