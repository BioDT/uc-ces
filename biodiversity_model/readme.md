# BioDT Cultural Ecosystem Services pDT - Biodiversity Component

## Overview

Species distribution models for species that provide cultural ecosystem services. This model is intended to be run on the BioDT infrastructure. This is a work in progress.

Key files:

 * The main workflow currently takes place in `biodiversity_model_workflow.Rmd`.
 * The model arguments are handled through the command line using `run_biodiversity_model.R`.
 * However, if running in a Docker environment, The model arguments are first handed by `entrypoint.sh`, which then runs `run_biodiversity_model.R`.

The modelling is done in R using the following packages:

 * The models are fitted uising [tidymodels](https://www.tidymodels.org/)
 * Raster processing is done using [terra](https://rspatial.github.io/terra/reference/terra-package.html)
 * Species data is accessed using the [rgbif](https://cran.r-project.org/web/packages/rgbif/index.html) 

## Input data

### Species occurence data

GBIF data is accessed by API using `rgbif` package.

### Environmental covariate data

Environmental co-variate data is loaded as a `.tif` file. This is currently loaded from the `inputs` folder. You get some example data from here: [env-layers.tif](https://drive.google.com/file/d/1veEX3RG_JXu_ZYu2oQMbWQ2v0R2dt4fW/view?usp=sharing) (hosted temporarily on Google Drive). Put this file into the `inputs` folder.

## Outputs

The model produces 2 outputs:

 * A map of predicted species distribution in `.tif` file format (raster). It is saved as `prediction_TAXONKEY_YYYY-MM-DD.tif` in `outputs/maps`
 * A `.html` format report (rendered by rmarkdown) with model diagnostics. It is saved as `report_TAXONKEY_YYYY-MM-DD.html` in `outputs/reports`
 
## Running the model

### Not containerised

For testing, the model can be run non-containerised. It is called from the command line using `Rscript` with arguments.

```
Rscript run_biodiversity_model.R TAXONKEY MODEL_OUTPUT_LOCATION REPORT_OUTPUT_LOCATION N_BOOTSTRAPS
```

 * `TAXONKEY` - the key of the taxon (could be species or other taxonomic level) see: https://discourse.gbif.org/t/understanding-gbif-taxonomic-keys-usagekey-taxonkey-specieskey/3045
 * `MODEL_OUTPUT_LOCATION` - file location where the model output is saved
 * `REPORT_OUTPUT_LOCATION` - file locaton of where the report is saved
 * `N_BOOTSTRAPS` - how many bootstraps to use when computing model variability eg. 5

For example:
```                                                                                
Rscript run_biodiversity_model.R 5334220 outputs/maps outputs/reports 5
```                                                                            

The `run_biodiversity_model.R` file actually triggers `biodiversity_model_workflow.Rmd` which contains all the actual modelling code.

### Containerised (Docker)

The model can be run in a docker container. Build the Docker image (which we'll call `ces-biodiversity`) by locating yourself in the `biodiversity_model` directory then run:

```
docker build -t ces-biodiversity .
```

This builds a Docker image using the `Dockerfile`. The base image is `rocker/geospatial:4.3.1`. You can see the list of packages that come installed here: https://github.com/rocker-org/rocker-versioned2/wiki 

The Docker build process installs any extra R packages with lines like so `RUN R -e 'install.packages("tidymodels")' `. It the copies any necessary files into the docker container from the host. Creates folders for the outputs.

We also copy an entry point shell file `entrypoint.sh`. The entry point script will receive the command line arguments and pass them to the R script. This script simply runs the R script (`run_biodiversity_model.R`) using the Rscript command and passes the command line arguments (`"$@"`) to it.

This means to run the model in a docker container you use this command:

```
docker run ces-biodiversity TAXONKEY MODEL_OUTPUT_LOCATION REPORT_OUTPUT_LOCATION N_BOOTSTRAPS
```

By default, when your script saves an output within a Docker container, it will be saved inside the container itself. However, if you want to persist the output outside the container, you can use Docker's volume feature to map a directory on your host machine to a directory within the container. Change the `-v` argument file path to whatever output folder you want to the files to be saved to. Use absolute paths. For example here's the volume I use on my laptop.

```
docker run -v C:/Users/simrol/Documents/R_2023/uc-ces/biodiversity_model/outputs:/outputs ces-biodiversity TAXONKEY MODEL_OUTPUT_LOCATION REPORT_OUTPUT_LOCATION N_BOOTSTRAPS
```

Here's a full example with real arguments.

```
docker run -v C:/Users/simrol/Documents/R_2023/uc-ces/biodiversity_model/outputs:/outputs ces-biodiversity 5334220 outputs/maps outputs/reports 5
```

This is the sort of response we expect when the model runs correctly:

```
$ docker run -v C:/Users/simrol/Documents/R_2023/uc-ces/biodiversity_model/outputs:/outputs ces-biodiversity 5334220 out
puts/maps outputs/reports 5
[1] "Arguments:"
[1] "5334220"
[1] "outputs/maps"
[1] "outputs/reports"
[1] "5"
[1] "Working directory:"
[1] "/"
[1] "Pandoc available"
$version
[1] ‘3.1.1’

$dir
[1] "/usr/local/bin"



processing file: biodiversity_model_workflow.Rmd
1/23
2/23 [setup]
3/23
4/23 [packages]
5/23
6/23 [load_gbif_data]
7/23
8/23 [load_environmental_data]
9/23
10/23 [process_data]
11/23
12/23 [fit_models]
13/23
14/23 [eval_model_performance]
15/23
16/23 [predict]
17/23
18/23 [plot]
19/23
20/23 [export]
21/23
22/23 [session_info]
23/23
output file: biodiversity_model_workflow.knit.md

/usr/local/bin/pandoc +RTS -K512m -RTS biodiversity_model_workflow.knit.md --to html4 --from markdown+autolink_bare_uris+tex_math_single_backslash --output outputs/reports/report_5334220_2023-06-30.html --lua-filter /usr/local/lib/R/site-library/rmarkdown/rmarkdown/lua/pagebreak.lua --lua-filter /usr/local/lib/R/site-library/rmarkdown/rmarkdown/lua/latex-div.lua --embed-resources --standalone --variable bs3=TRUE --section-divs --template /usr/local/lib/R/site-library/rmarkdown/rmd/h/default.html --no-highlight --variable highlightjs=1 --variable theme=bootstrap --mathjax --variable 'mathjax-url=https://mathjax.rstudio.com/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML' --include-in-header /tmp/Rtmpx8N1qb/rmarkdown-str86c658a8a.html

Output created: outputs/reports/report_5334220_2023-06-30.html
```

### Troubleshooting

This error results from line ending issues

```
standard_init_linux.go:228: exec user process caused: no such file or directory
```

When developing code for Docker containers then check for line ending issues: If you're working on a Windows machine and sharing files with a Linux-based Docker container, line ending differences can sometimes cause issues. Ensure that the entry point script and the Dockerfile have Unix-style line endings (LF). You can use a text editor with the ability to save files with Unix-style line endings or use tools like dos2unix to convert the line endings.




