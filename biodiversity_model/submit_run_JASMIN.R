module load jasr

setwd("BioDT_SDMs")

library(rmarkdown)
library(rslurm)
library(dplyr)

tif_paths = c("../inputs/Cairngorms/cairngorms_env_layers.tif", "inputs/Stirlingshire/BIO_stirlingshire.tif", "inputs/Tweed valley/BIO_tweed_valley.tif", "inputs/Scotland/bio_image_scotland_1000.tif", "inputs/Scotland/bio_image_scotland_100.tif")
shp_paths = c("../inputs/Cairngorms/SG_CairngormsNationalPark_2010.shp", "inputs/Stirlingshire/Stirlingshire.shp", "inputs/Tweed valley/Tweed Catchment.shp", "inputs/Scotland/countries_uk.shp", "inputs/Scotland/countries_uk.shp")
region_names = c("cairngorms", "stirlingshire", "tweed_valley", "scotland_1000", "scotland_100")

species_df = read.csv("species_info/cairngorms_sp_list.csv")

species_names = species_df$sci_name
keys = species_df$speciesKey

run_workflow = function(species_i){

taxonkey = keys[species_i]
species_name = species_names[species_i]

print(taxonkey)
print(species_name)

species_folder_name = tolower(gsub(" |\\.", "_", species_name))
species_folder_name = tolower(gsub("__", "_", species_folder_name))

for (region_i in 1:length(tif_paths)){

tif_path = tif_paths[region_i]
shp_path = shp_paths[region_i]
region_name = region_names[region_i]

print(tif_path)
print(shp_path)

#run model using R markdown file
rmarkdown::render(input = "../biodiversity_model_workflow_flexsdm_ODMAP.Rmd",
                  output_file = paste0("report_", taxonkey, "_", region_name,".html"),
                  params = list(
                  taxonkey = taxonkey,
                  out_file = paste0("prediction_", taxonkey, "_", region_name, "_", format(Sys.Date(), "%Y-%m-%d"), ".tif"),
                  env_layers_path = tif_path,
                  study_region_boundary_path = shp_path,
                  species_folder_name = species_folder_name,
                  region_name = region_name
                  ),
                  envir = new.env()
                  )
}

}

# run_workflow(61)

jobname <- paste0('dylcar_sdm_fitting_', format(Sys.Date(), "%d_%m_%Y"))

# Slurm job submission
sjob <- slurm_apply(
  f = run_workflow,
  params = data.frame(species_i = 1:length(taxa)),
  jobname = jobname,
  nodes = length(taxa),
  cpus_per_node = 1,
  submit = TRUE,
  global_objects = c(),
  slurm_options = list(time = "24:00:00", mem = 30000, error = "%a.err",
  account = "ceh_generic", partition = "standard", qos = "short") ### HERE
)
