# Base image https://hub.docker.com/u/rocker/
FROM rocker/geospatial:4.3.1

#install R packages
RUN R -e 'install.packages("tidymodels")'
RUN R -e 'install.packages("rgbif")'
RUN R -e 'install.packages("spThin")'

#R packages included in base image so no need to install (hence commented out):
#RUN R -e 'install.packages("rmarkdown")' 
#RUN R -e 'install.packages("dplyr")'
#RUN R -e 'install.packages("terra")'
#RUN R -e 'install.packages("sf")'

RUN R -e 'install.packages("remotes")'
RUN R -e 'remotes::install_github("sjevelazco/flexsdm@HEAD")'




## copy files
COPY run_biodiversity_model.R run_biodiversity_model.R
COPY biodiversity_model_workflow_flexsdm.Rmd biodiversity_model_workflow_flexsdm.Rmd

# environmental raster data
COPY /inputs/env-layers.tif /inputs/env-layers.tif

#make folders for saving outputs
RUN mkdir -p /outputs/maps
RUN mkdir -p /outputs/reports

# Copy the entry point script into the container
COPY /entrypoint.sh /entrypoint.sh

# Make the entry point script executable
RUN chmod +x entrypoint.sh

# Set the entry point script as the entry point of the container
ENTRYPOINT ["/entrypoint.sh"]
