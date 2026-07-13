#!/bin/bash

# =============================================================================
# MELODIC ICA: SLURM array job
# =============================================================================
#
# Purpose
# -------
# Run FSL MELODIC independent component analysis (ICA) for each fMRI run from every subject using a SLURM job array.
#
# For each subject, the script processes:
#   - two resting-state runs
#   - two cartoon runs
#
# MELODIC decomposes each preprocessed fMRI time series into spatially independent components and their associated time courses. 
# These outputs are subsequently inspected to identify plausible functional brain networks.
#
# Inputs
# ------
# - Subject list:
#     /scratch/users/k20009014/subjects_ses01.txt
# - Preprocessed volumetric fMRI data:
#     derivatives_batch/<subject>/MNINonLinear/Results/<run>/<run>.nii.gz
# - HCP Pipelines container:
#     /scratch/users/k20009014/hcppipelines_latest.sif
#
# Outputs
# -------
# One MELODIC .ica directory is created per run under:
#     derivatives_batch/<subject>/MELODIC/
#
# Each output directory contains the ICA spatial maps, component time courses, summary files and an HTML report.
#
# Notes
# -----
# - One SLURM array task processes one subject.
# - All four runs are processed sequentially within that task.
# - The repetition time is fixed at 2.0 seconds.
# - Brain extraction is disabled because the input data have already passed through the HCP preprocessing workflow.
# =============================================================================


# -------------------------------------------------------------------------
# SLURM resource requests and logging
# -------------------------------------------------------------------------

#SBATCH --job-name=melodic_batch
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=8
#SBATCH --mem=32G
#SBATCH --time=12:00:00
#SBATCH --array=1-12

# %A is the parent SLURM job ID and %a is the array-task ID.
#SBATCH --output=/scratch/users/k20009014/logs/melodic_%A_%a.out
#SBATCH --error=/scratch/users/k20009014/logs/melodic_%A_%a.err


# -------------------------------------------------------------------------
# Select the subject assigned to the current array task
# -------------------------------------------------------------------------

# Read the line corresponding to SLURM_ARRAY_TASK_ID from the subject list.
SUBJECT=$(sed -n "${SLURM_ARRAY_TASK_ID}p" /scratch/users/k20009014/subjects_ses01.txt)


# -------------------------------------------------------------------------
# Execute MELODIC inside the container
# -------------------------------------------------------------------------

# Mount the user's scratch directory as /work inside the container.
singularity exec \
--bind /scratch/users/k20009014:/work \
/scratch/users/k20009014/hcppipelines_latest.sif \
bash -c "

# Exit immediately if a command fails or an undefined variable is used.
set -eu

# Subject identifier passed from the SLURM array task.
Subject=${SUBJECT}

# Create a subject-specific directory for all MELODIC outputs.
OUTDIR=/work/derivatives_batch/\${Subject}/MELODIC
mkdir -p \${OUTDIR}


# -------------------------------------------------------------------------
# Define the functional runs to analyse
# -------------------------------------------------------------------------

Runs=(
  task-rest_run-01
  task-rest_run-02
  task-cartoon_run-01
  task-cartoon_run-02
)


# -------------------------------------------------------------------------
# Run MELODIC ICA for each functional run
# -------------------------------------------------------------------------

for RunName in \${Runs[@]}; do

  # Input preprocessed fMRI volume from the HCP MNINonLinear results folder.
  INPUT=/work/derivatives_batch/\${Subject}/MNINonLinear/Results/\${RunName}/\${RunName}.nii.gz

  # Output directory for the ICA results from the current run.
  OUTPUT=\${OUTDIR}/\${RunName}.ica

  # Record progress in the SLURM output log.
  echo Running MELODIC for \${Subject} \${RunName}

  # Run spatial ICA using FSL MELODIC.
  #
  # Key options:
  # - --tr=2.0: specify the 2-second repetition time.
  # - --nobet: skip brain extraction because preprocessing is already complete.
  # - --bgthreshold=10: set the background-intensity threshold.
  # - --mmthresh=0.5: set the mixture-model threshold used for component maps.
  # - --report: generate the HTML component report.
  melodic \
    -i \${INPUT} \
    -o \${OUTPUT} \
    --tr=2.0 \
    --nobet \
    --bgthreshold=10 \
    --mmthresh=0.5 \
    --report
done
"
