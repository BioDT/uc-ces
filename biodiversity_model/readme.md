# BioDT Cultural Ecosystem Services pDT - Biodiversity Component

## Overview

Species distribution models for species that provide cultural ecosystem services. This model is intended to be run on the BioDT infrastructure.

The models are fitted uising tidymodels https://www.tidymodels.org/

Raster processing is done in [terra](https://rspatial.github.io/terra/reference/terra-package.html)

## Input data

GBIF data is accessed by API using `rgbif` package
Environmental co-variate data is loaded as a `.tif` file. This is currently loaded from the `inputs` folder.

## Output

The model produces 2 outputs:

 * A map of predicted species distribution in .tif file format
 * A report (rendered by rmarkdown) with model diagnositics etc.

## Running the model

It is called from the command line using

```
Rscript run_biodiversity_model.R TAXONKEY MODEL_OUTPUT_LOCATION REPORT_OUTPUT_LOCATION N_BOOTSTRAPS
```

 * `TAXONKEY` - the key of the taxon (could be species or other taxonomic level) see: https://discourse.gbif.org/t/understanding-gbif-taxonomic-keys-usagekey-taxonkey-specieskey/3045
 * `MODEL_OUTPUT_LOCATION` - file location where the model output is saved
 * `REPORT_OUTPUT_LOCATION` - file locaton of where the report is saved
 * `N_BOOTSTRAPS` - how many bootstraps to use when computing model variability, 5 is a good default to use

For example:
```                                                                                
Rscript run_biodiversity_model.R 5334220 outputs/maps outputs/reports 5
```                                                                            

The `run_biodiversity_model.R` file actually triggers `biodiversity_model_workflow.Rmd` which contains all the actual modelling code.


