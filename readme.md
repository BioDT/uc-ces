# Models for Cultural Ecosystem Services Prototype Digital Twin

This GitHub repository contains the model code required to run models to deliver the cultural ecosystem services pDT (previously 'use-case'). Readme last updated 28th July 2023.

For more general background about the pDT then please visit the wiki page: https://wiki.eduuni.fi/display/cscRDIcollaboration/4.1.1.2.1+Cultural+Ecosystem+Services

Please use the GitHub issues to discuss any development: https://github.com/BioDT/uc-ces/issues

The `diagrams` folder contains any diagrams which can be edited with https://app.diagrams.net/

## Digital Twin components

![pipelines report diagram drawio (3)](https://github.com/BioDT/uc-ces/assets/17750766/c27cdbe3-85bd-4d6a-9b92-59ef5e9e5aaf)

The Digital Twin comprises of two components: the recreation potential model and the biodiversity model. More detail about each model can be found on their corresponding readme within the repository:

 * https://github.com/BioDT/uc-ces/tree/main/biodiversity_model
 * https://github.com/BioDT/uc-ces/tree/main/recreation_model

Both models are :

 * implemented in R
 * configured to be run from command line
 * developed to run in a container, either Docker (if running on a local computing device) or singularity (also known as apptainer) when running on HPC (https://docs.lumi-supercomputer.eu/software/containers/singularity/)

The user interface for the pDT will be developed as a module within the BioDT Shiny app (https://github.com/BioDT/biodt-shiny) 

## Running the models on LUMI

Note that I (Simon) usually have to re-add my ssh key to the agent every time I log into LUMI with:
```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/lumi-simrol
```
