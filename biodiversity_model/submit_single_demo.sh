#!/bin/bash
#SBATCH --job-name=ecosystem_services_biodiversity
#SBATCH --account=project_465000915
#SBATCH --time=00:10:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --partition=small

singularity exec --bind "$PWD" /projappl/project_465000915/simonrolph/ces-biodiversity_0.2.0.sif Rscript run_biodiversity_model.R 5334220 outputs/maps outputs/reports 5
