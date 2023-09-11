# input is a folder of raster files, a folder of csv files and the name of the column in each csv to use
# output is a list of rasters
reclassify_rasters <- function(raster_folder, Score_column) {
  # Get a list of all files in the folder
  raster_files <- list.files(raster_folder, pattern=".tif$", full.names = TRUE)

  # Initialize a list to store the modified raster objects
  modified_rasters <- list()

  # Loop through each raster file
  for (raster_file in raster_files) {
    # Construct the path to the CSV of scores
    csv_file <- file.path(paste0(file_path_sans_ext(raster_file), ".csv"))

    # Check if the CSV file exists
    if (!file.exists(csv_file)) {
      cat("CSV file", csv_file, "not found for raster", raster_file, ". Aborting\n")
      return(NULL)
    }

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

    # Add the modified raster object to the list using the output file name as the key
    modified_rasters[[raster_file]] <- r
  }

  # Return the modified rasters
  return(modified_rasters)
}
