#!/bin/bash
#SBATCH --job-name=ecosystem_services_biodiversity
#SBATCH --account=project_465000915
#SBATCH --time=00:20:00
#SBATCH --array=1-400
#SBATCH --output=hpc_logs/%A_%a.out
#SBATCH --error=hpc_logs/%A_%a.err
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=16G
#SBATCH --partition=small
#SBATCH --mail-type=all

# Read the numeric ID from the text file based on the array task ID
ID=$(sed -n "${SLURM_ARRAY_TASK_ID}p" species_info/taxonIDs.txt)
echo "Processing ID: $ID"

singularity exec --bind "$PWD" /projappl/project_465000915/simonrolph/ces-biodiversity_0.2.0.sif Rscript run_biodiversity_model.R $ID outputs/maps outputs/reports 5
