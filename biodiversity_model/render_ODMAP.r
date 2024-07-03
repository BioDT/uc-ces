# Function to obtain elements in each subsection from a dictionary data frame
obtain_subsection_ids <- function(section_name, subsection_text) {
  # Filter the dictionary for the given subsection
  odmap_dict_sub = odmap_dict %>% filter(section == section_name, subsection == subsection_text)
  elements = odmap_dict_sub$element_id

  # Process names in the input list
  input_list_stemmed_names = unlist(sapply(names(input_list), USE.NAMES = F, FUN = function(name) {
    last_underscore <- max(gregexpr("_", name)[[1]])
    substr(name, 1, last_underscore - 1)
  }))
}

# Define a function to search the script code use
script_search <- function(regex, script) {
  lines <- readLines(script, warn = FALSE)
  any(sapply(lines, FUN = function(line) {
    trimmed_line <- trimws(line) # Remove leading and trailing whitespace
    !startsWith(trimmed_line, "#") && grepl(regex, trimmed_line) && !grepl("script_search", trimmed_line)
  }))
}

# Function to obtain a description for a given ID from a dictionary data frame
obtain_description <- function(id) {
  # Check if the ID exists in the dictionary
  if (!(id %in% odmap_dict$element_id)) {
    last_underscore <- max(gregexpr("_", id)[[1]])
    id <- substr(id, 1, last_underscore - 1)
  }

  # Retrieve description and text entry for the ID
  description = odmap_dict %>% filter(element_id == id) %>% pull(element_placeholder)
  text_entry = odmap_dict %>% filter(element_id == id) %>% pull(Value)

  # Print the description and text entry if available
  if (!is.na(text_entry) && identical(text_entry, character(0)) == FALSE && text_entry != "") {
    print(paste0(description, "    Entry found: ", text_entry))
  } else {
    print(description)
  }
}

render_ODMAP <- function(odmap_dict_path = "odmap_dict.csv",
                              raster_path = "untitled.tif",
                              model_development_script_path = "biodiversity_model_workflow_flexsdm_ODMAP.Rmd",
                              odmap_generate_report_path = "ODMAP_generate_report.Rmd",
                              o_authorship_1 = NULL, o_authorship_3 = NULL, o_authorship_4 = NULL, 
                              o_objective_1 = NULL, o_objective_2 = NULL, 
                              o_location_1 = NULL, o_scale_2 = NULL, o_scale_3 = NULL, o_scale_4 = NULL, o_scale_5 = NULL, 
                              o_bio_1 = NULL, o_bio_2 = NULL, o_concept_1 = NULL, o_assumptions_1 = NULL, o_algorithms_1 = NULL, 
                              o_algorithms_2 = NULL, o_algorithms_3 = NULL, o_workflow_1 = NULL, 
                              o_software_2 = NULL, o_software_3 = NULL, 
                              d_bio_2 = NULL, d_bio_3 = NULL, d_bio_5 = NULL, d_bio_7 = NULL, d_bio_9 = NULL, d_bio_10 = NULL, 
                              d_bio_12 = NULL, d_part_2 = NULL, d_pred_2 = NULL, d_pred_4 = NULL, d_pred_5 = NULL, 
                              d_pred_6 = NULL, d_pred_7 = NULL, d_pred_8 = NULL, d_pred_9 = NULL, d_pred_10 = NULL, 
                              d_proj_2_xmin = NULL, d_proj_2_xmax = NULL, d_proj_2_ymin = NULL, d_proj_2_ymax = NULL,
                              d_proj_3 = NULL, d_proj_4 = NULL, d_proj_5 = NULL, d_proj_6 = NULL, d_proj_7 = NULL, d_proj_8 = NULL, 
                              m_preselect_1 = NULL, m_multicol_1 = NULL, m_settings_2 = NULL, m_estim_1 = NULL, 
                              m_estim_2 = NULL, m_estim_3 = NULL, m_selection_1 = NULL, m_selection_2 = NULL, 
                              m_selection_3 = NULL, m_depend_1 = NULL, m_depend_2 = NULL, m_depend_3 = NULL, 
                              m_threshold_1 = NULL, a_perform_1 = NULL, a_perform_3 = NULL, 
                              a_plausibility_1 = NULL, a_plausibility_2 = NULL, p_output_1 = NULL, 
                              p_uncertainty_1 = NULL, p_uncertainty_2 = NULL, 
                              p_uncertainty_3 = NULL, p_uncertainty_4 = NULL, p_uncertainty_5 = NULL) {
  
  # List variables left with NULL values
  params <- as.list(match.call()[-1])
  null_params <- names(params)[sapply(params, is.null)]
  if (length(null_params) > 0) {
    message("The following parameters were left with NULL values: ", paste(null_params, collapse = ", "))
  }

  # Load your SpatRaster object
  output_raster_object <- rast(raster_path)
  input_list <- list()

  # Internal object generation
  target_species <- gbif_data$scientificName %>% first()
  extent <- ext(output_raster_object)
  sess_info <- sessionInfo()
  loaded_packages <- sess_info$otherPkgs
  package_version_strings <- sapply(names(loaded_packages), function(pkg) {
    paste(pkg, "version", loaded_packages[[pkg]]$Version, sep = " ")
  })
  packages_versions <- paste(package_version_strings, collapse = " \n\n")
  species_phylum <- gbif_data %>% filter(scientificName == target_species) %>% first() %>% pull(phylum) %>% unique()
  species_order <- gbif_data %>% filter(scientificName == target_species) %>% first() %>% pull(order) %>% unique()
  species_family <- gbif_data %>% filter(scientificName == target_species) %>% first() %>% pull(family) %>% unique()
  sample_size <- gbif_data %>% filter(scientificName == target_species) %>% nrow()
  doi <- "your_doi_here"  # replace with actual DOI
  access_datetime <- Sys.time()
  
  # Populate input_list
  input_list$o_authorship_1 <- o_authorship_1
  input_list$o_authorship_3 <- o_authorship_3
  input_list$o_authorship_4 <- o_authorship_4
  input_list$o_objective_1 <- o_objective_1
  input_list$o_objective_2 <- o_objective_2
  input_list$o_taxon_1 <- target_species
  input_list$o_location_1 <- o_location_1
  input_list$o_scale_1_xmin <- as.character(extent[1])
  input_list$o_scale_1_xmax <- as.character(extent[2])
  input_list$o_scale_1_ymin <- as.character(extent[3])
  input_list$o_scale_1_ymax <- as.character(extent[4])
  input_list$o_scale_2 <- o_scale_2
  input_list$o_scale_3 <- o_scale_3
  input_list$o_scale_4 <- o_scale_4
  input_list$o_scale_5 <- o_scale_5
  input_list$o_bio_1 <- o_bio_1
  input_list$o_bio_2 <- o_bio_2
  input_list$o_concept_1 <- o_concept_1
  input_list$o_assumptions_1 <- o_assumptions_1
  input_list$o_algorithms_1 <- o_algorithms_1
  input_list$o_algorithms_2 <- o_algorithms_2
  input_list$o_algorithms_3 <- o_algorithms_3
  input_list$o_workflow_1 <- o_workflow_1
  input_list$o_software_1 <- paste("Written using", R.Version()$version.string, "with packages:\n\n", packages_versions)
  input_list$o_software_2 <- o_software_2
  input_list$o_software_3 <- o_software_3
  input_list$d_bio_1 <- paste("Species: ", target_species, ", phylum: ", species_phylum, ", order: ", species_order, ", family: ", species_family, sep = "")
  input_list$d_bio_2 <- d_bio_2
  input_list$d_bio_3 <- d_bio_3
  input_list$d_bio_4 <- paste0("data obtained from GBIF API with DOI: ", doi, " at datetime: ", access_datetime)
  input_list$d_bio_5 <- d_bio_5
  input_list$d_bio_6 <- paste("species: ", target_species, ", sample size = ", sample_size, sep = "")
  input_list$d_bio_7 <- d_bio_7
  input_list$d_bio_8 <- paste0("Spatial thinning: ", script_search("occfilt_env", script = model_development_script_path), ifelse(script_search("occfilt_env", script = model_development_script_path), "\n\nThinned occurrences based on environmental space", ""), "\n\n", "temporal thinning: FALSE")
  input_list$d_bio_9 <- d_bio_9
  input_list$d_bio_10 <- d_bio_10
  input_list$d_bio_11 <- paste0("Species occurrences plotted for only species: ", target_species, "\n\n", "Spatial buffer: ", script_search("calib_area", script = model_development_script_path), ifelse(script_search("calib_area", script = model_development_script_path), "\n\nEstablished spatial buffers from occurrences with 5 km radius", ""))
  input_list$d_bio_12 <- d_bio_12
  input_list$d_part_1 <- paste0("random partitioning: ", script_search("part_random", script = model_development_script_path), ifelse(script_search("part_random", script = model_development_script_path), paste("\n\n", "Conducted in flexsdm using 4 fold random partitioning"), ""))
  input_list$d_part_2 <- d_part_2
  input_list$d_part_3 <- paste0("Random partitioning: ", script_search("part_random", script = model_development_script_path), ifelse(script_search("part_random", script = model_development_script_path), paste("\n\n", "Conducted in flexsdm using 4 fold random partitioning"), ""))
  input_list$d_pred_1 <- paste(names(env_data), collapse = ", ")
  input_list$d_pred_2 <- d_pred_2
  input_list$d_pred_3_xmin <- extent[1]
  input_list$d_pred_3_xmax <- extent[2]
  input_list$d_pred_3_ymin <- extent[3]
  input_list$d_pred_3_ymax <- extent[4]
  input_list$d_pred_4 <- d_pred_4
  input_list$d_pred_5 <- d_pred_5
  input_list$d_pred_6 <- d_pred_6
  input_list$d_pred_7 <- d_pred_7
  input_list$d_pred_8 <- d_pred_8
  input_list$d_pred_9 <- d_pred_9
  input_list$d_pred_10 <- d_pred_10
  input_list$d_proj_1 <- paste0("data obtained from GBIF API with DOI: ", doi, " at datetime: ", access_datetime)
  input_list$d_proj_2_xmin <- d_proj_2_xmin
  input_list$d_proj_2_xmax <- d_proj_2_xmax
  input_list$d_proj_2_ymin <- d_proj_2_ymin
  input_list$d_proj_2_ymax <- d_proj_2_ymax
  input_list$d_proj_3 <- d_proj_3
  input_list$d_proj_4 <- d_proj_4
  input_list$d_proj_5 <- d_proj_5
  input_list$d_proj_6 <- d_proj_6
  input_list$d_proj_7 <- d_proj_7
  input_list$d_proj_8 <- d_proj_8
  input_list$m_preselect_1 <- m_preselect_1
  input_list$m_multicol_1 <- m_multicol_1
  input_list$m_settings_1 <- data.frame(
    Model = c("Gaussian", "GLM", "SVM"),
    Family = c("gaussian", "gaussian", NA),
    Formula = paste("predictors:", paste(names(env_data), collapse = "; ")),
    Weights = "none",
    Notes = ""
  )
  input_list$m_settings_2 <- m_settings_2
  input_list$m_estim_1 <- m_estim_1
  input_list$m_estim_2 <- m_estim_2
  input_list$m_estim_3 <- m_estim_3
  input_list$m_selection_1 <- m_selection_1
  input_list$m_selection_2 <- m_selection_2
  input_list$m_selection_3 <- m_selection_3
  input_list$m_depend_1 <- m_depend_1
  input_list$m_depend_2 <- m_depend_2
  input_list$m_depend_3 <- m_depend_3
  input_list$m_threshold_1 <- m_threshold_1
  input_list$a_perform_1 <- a_perform_1
  input_list$a_perform_2 <- "For each model, we selected three threshold values to generate binary suitability predictions: the threshold that maximizes TSS (max_sens_spec), the threshold at which sensitivity and specificity are equal (equal_sens_spec), and the threshold at which the Sorenson index is highest (max_sorenson)."
  input_list$a_perform_3 <- a_perform_3
  input_list$a_plausibility_1 <- a_plausibility_1
  input_list$a_plausibility_2 <- a_plausibility_2
  input_list$p_output_1 <- p_output_1
  input_list$p_output_2 <- paste0("Adjustments for overprediction: ", script_search("msdm_posteriori", script = model_development_script_path), ifelse(script_search("msdm_posteriori", script = model_development_script_path), "\n\nThe overprediction of SDMs was corrected for based on occurrence records and suitability patterns.", ""))
  input_list$p_uncertainty_1 <- p_uncertainty_1
  input_list$p_uncertainty_2 <- p_uncertainty_2
  input_list$p_uncertainty_3 <- p_uncertainty_3
  input_list$p_uncertainty_4 <- p_uncertainty_4
  input_list$p_uncertainty_5 <- p_uncertainty_5

  odmap_dict <- read_csv(odmap_dict_path)

  # Render the R Markdown to a Word document
  render(
    input = file.path(getwd(), odmap_generate_report_path),
    output_format = "word_document",
    output_file = file.path(getwd(), "ODMAP_report.docx"),
    params = input_list
  )

  message("ODMAP documentation generated.")
}

