reclassify_rasters <- function(raster_folder, csv_folder, Score_column, output_folder) {
  # Get a list of all raster files in the folder (excluding auxiliary files)
  raster_files <- list.files(raster_folder, pattern = "^Raster_.*\\.tif$", full.names = TRUE)

  # Initialize a list to store the modified raster objects
  modified_rasters <- list()

  # Loop through each raster file
  for (raster_file in raster_files) {
    # Extract the raster name without the path and prefix
    raster_name <- gsub("^Raster_", "", file_path_sans_ext(basename(raster_file)))

    # Construct the corresponding CSV file path
    csv_file <- file.path(csv_folder, paste0("Scores_", raster_name, ".csv"))

    # Check if the CSV file exists
    if (!file.exists(csv_file)) {
      cat("CSV file", csv_file, "not found for raster", raster_name, ". Skipping.\n")
      next
    }

    # Create the output file path with Score_column name
    output_file <- file.path(output_folder, paste0("Scored_", raster_name, "_", Score_column, ".tif"))

    # Load the raster
    r <- raster(raster_file)

    # Load the CSV table
    table <- read.csv(csv_file)

    # Check data type compatibility and convert if necessary
    if (!is.numeric(table$Raster_Val)) {
      table$Raster_Val <- as.numeric(table$Raster_Val)
    }
    if (!is.numeric(table[[Score_column]])) {
      table[[Score_column]] <- as.numeric(table[[Score_column]])
    }

    # Reclassify raster values based on CSV table
    r[] <- table[[Score_column]][match(getValues(r), table$Raster_Val)]

    # Set NA values to 0
    r[is.na(r)] <- 0

    # Save the modified raster
    writeRaster(r, output_file, format = "GTiff", overwrite = TRUE)

    # Print a success message
    cat("Raster reclassification completed. Modified raster saved to", output_file, "\n")

    # Add the modified raster object to the list using the output file name as the key
    modified_rasters[[basename(output_file)]] <- r
  }

  # Return the list of modified raster objects
  return(modified_rasters)
}
