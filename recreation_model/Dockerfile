# Base image https://hub.docker.com/r/rocker/geospatial
FROM rocker/geospatial:4.3.1

## copy files
RUN mkdir /model /input /output
COPY FUNC_Calculate_Euclidean_Distance.R \
		 FUNC_Normalise_Rasters.R \
		 FUNC_Process_Raster_Proximity.R \
		 FUNC_Raster_Reclassifier.R \
		 MODEL_Recreation_potential.R \
		 /model/

VOLUME ["/input", "/output"]
WORKDIR /model
ENTRYPOINT ["Rscript", "MODEL_Recreation_potential.R"]
