#!/bin/bash

# =============================================================================
# HCP PreFreeSurfer pipeline: SLURM array job
# =============================================================================
# Purpose
# -------
# Run the HCP PreFreeSurfer structural preprocessing stage for multiple subjects using a SLURM job array and a Singularity container.
#
# Each array task reads one subject identifier from a text file, locates that subject's T1-weighted image, and runs PreFreeSurferPipeline.sh inside the HCP Pipelines container.
#
# Inputs
# ------
# - Subject list: /scratch/users/k20009014/subjects_ses01.txt
# - T1-weighted image: <subject directory>/anat/<subject>_ses-01_T1w.nii
# - Container: /scratch/users/k20009014/hcppipelines_latest.sif
#
# Outputs
# -------
# - PreFreeSurfer derivatives: /scratch/users/k20009014/derivatives_batch
# - SLURM logs: /scratch/users/k20009014/logs/
#
# Notes
# -----
# - The array range 1-12 assumes that the subject list contains 12 entries.
# - T2-weighted and field-map inputs were unavailable and are set to NONE.
# - The pipeline uses LegacyStyleData processing mode.
# =============================================================================

# SLURM resources and logging.
#SBATCH --job-name=PreFS_batch
#SBATCH --partition=cpu
#SBATCH --cpus-per-task=4
#SBATCH --mem=32G
#SBATCH --time=06:00:00
#SBATCH --array=1-12

# %A is the parent job ID and %a is the array-task ID.
#SBATCH --output=/scratch/users/k20009014/logs/PreFS_%A_%a.out
#SBATCH --error=/scratch/users/k20009014/logs/PreFS_%A_%a.err

# Select the subject assigned to the current array task by reading the corresponding line from the subject list.
SUBJECT=$(sed -n "${SLURM_ARRAY_TASK_ID}p" /scratch/users/k20009014/subjects_ses01.txt)

# Run the HCP Pipelines container. 
# Environment variables define the FreeSurfer licence and HCP installation paths. 
# Bind mounts expose the working directory as /work and the source imaging dataset as /data inside the container.
singularity exec \
--env FS_LICENSE=/work/license.txt \
--env HCPPIPEDIR=/work/HCPpipelines_shang/HCPpipelines \
--env HCPPIPEDIR_Global=/work/HCPpipelines_shang/HCPpipelines/global \
--env HCPPIPEDIR_Templates=/work/HCPpipelines_shang/HCPpipelines/global/templates \
--env HCPPIPEDIR_Config=/work/HCPpipelines_shang/HCPpipelines/global/config \
--bind /scratch/users/k20009014:/work \
--bind /scratch/prj/cortical_imaging_biobank/GSW/ADULT:/data \
/scratch/users/k20009014/hcppipelines_latest.sif \
bash -c "

# Exit immediately if a command fails or an undefined variable is used.
set -eu

# Subject identifier passed in from the SLURM array task.
Subject=${SUBJECT}

# Root directory for all HCP preprocessing outputs.
StudyFolder=/work/derivatives_batch

# Support both possible dataset layouts:
#   /data/<subject>/ses-01/
#   /data/<subject>/
if [ -d /data/\${Subject}/ses-01 ]; then
  Base=/data/\${Subject}/ses-01
else
  Base=/data/\${Subject}
fi

# Construct the expected path to the subject's T1-weighted image.
T1wInputImages=\${Base}/anat/\${Subject}_ses-01_T1w.nii

# Print the resolved subject and paths to the SLURM log for traceability.
echo Subject: \${Subject}
echo Base: \${Base}
echo T1: \${T1wInputImages}
echo StudyFolder: \${StudyFolder}

# Run the PreFreeSurfer structural preprocessing stage.
# Key settings:
# - T1-only processing, because no T2 image was available.
# - MNI152 templates are supplied at 0.8 mm and 2 mm resolution.
# - FNIRT performs nonlinear registration using the supplied configuration.
# - Field-map, spin-echo and gradient-distortion inputs are disabled because
#   they were not available for this dataset.
\${HCPPIPEDIR}/PreFreeSurfer/PreFreeSurferPipeline.sh \
  --path=\${StudyFolder} \
  --session=\${Subject} \
  --t1=\${T1wInputImages} \
  --t2=NONE \
  --processing-mode=LegacyStyleData \
  --t1template=\${HCPPIPEDIR_Templates}/MNI152_T1_0.8mm.nii.gz \
  --t1templatebrain=\${HCPPIPEDIR_Templates}/MNI152_T1_0.8mm_brain.nii.gz \
  --t1template2mm=\${HCPPIPEDIR_Templates}/MNI152_T1_2mm.nii.gz \
  --t2template=\${HCPPIPEDIR_Templates}/MNI152_T2_0.8mm.nii.gz \
  --t2templatebrain=\${HCPPIPEDIR_Templates}/MNI152_T2_0.8mm_brain.nii.gz \
  --t2template2mm=\${HCPPIPEDIR_Templates}/MNI152_T2_2mm.nii.gz \
  --templatemask=\${HCPPIPEDIR_Templates}/MNI152_T1_0.8mm_brain_mask.nii.gz \
  --template2mmmask=\${HCPPIPEDIR_Templates}/MNI152_T1_2mm_brain_mask_dil.nii.gz \
  --brainsize=150 \
  --fnirtconfig=\${HCPPIPEDIR_Config}/T1_2_MNI152_2mm.cnf \
  --fmapmag=NONE \
  --fmapphase=NONE \
  --echodiff=NONE \
  --SEPhaseNeg=NONE \
  --SEPhasePos=NONE \
  --seechospacing=NONE \
  --seunwarpdir=NONE \
  --t1samplespacing=NONE \
  --t2samplespacing=NONE \
  --unwarpdir=z \
  --gdcoeffs=NONE \
  --avgrdcmethod=NONE \
  --topupconfig=NONE
"
