args = commandArgs(trailingOnly=TRUE) # get arguments from command line call

# Print the arguments
print("Arguments:")
for (arg in args) {
  print(arg)
}

#arguments
#1: species taxonid from GBIF
#2: output location for tiff
#3: output location for report
#4 n bootstraps for DECIDE model

#handle missing arguments
if (length(args)==0) {
  stop("At least one argument must be supplied", call.=FALSE)
}

print("Working directory:")
print(getwd())

library(rmarkdown)

# #where is pandoc
if(Sys.info()["sysname"] == "Windows"){
  Sys.setenv(RSTUDIO_PANDOC="C:/Program Files/RStudio/bin/quarto/bin/tools")
}

# Function to get the Pandoc path
if (rmarkdown::pandoc_available()) {
  print("Pandoc available")
  print(rmarkdown::find_pandoc())
} else {
  stop("Pandoc not found. Please make sure it is installed and accessible.")
}

#run model using R markdown file
rmarkdown::render(input = "biodiversity_model_workflow_flexsdm.Rmd",
                  output_file = paste0(args[3],"/report_",args[1],"_",Sys.Date(),".html"),
                  params = list(
                    taxonkey = args[1],
                    out_file = paste0(args[2],"/prediction_",args[1],"_",Sys.Date(),".tif"),
                    n_bootraps = args[4]
                  ),
                  envir = new.env()
                  )



