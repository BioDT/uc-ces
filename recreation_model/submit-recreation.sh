#!/bin/bash
#SBATCH --job-name=ecosystem_services_recreation
#SBATCH --account=project_465000357
#SBATCH --time=00:30:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --partition=small

singularity exec --pwd /model --bind /projappl/project_465000357/boltonwi/recreation-data-new-format/:/input,/projappl/project_465000357/boltonwi/recreation-output/:/output /projappl/project_465000357/boltonwi/ces-recreation_0.1.sif Rscript MODEL_Recreation_potential.R SR
