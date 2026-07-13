#!/bin/bash

# =============================================================================
# Submit the complete HCP preprocessing and MELODIC workflow
# =============================================================================
#
# Purpose
# -------
# Submit all stages of the preprocessing pipeline to SLURM in the required
# order:
#
#   1. PreFreeSurfer
#   2. FreeSurfer
#   3. PostFreeSurfer
#   4. fMRIVolume
#   5. fMRISurface
#   6. MELODIC ICA
#
# Each job is submitted with an `afterok` dependency on the preceding stage.
# This means the next stage is released only if the previous job completes successfully.
#
# The script records the SLURM job ID returned for each stage and prints a summary after all jobs have been submitted.
#
# Notes
# -----
# - This script submits the jobs; it does not wait for the full pipeline to finish.
# - The referenced stage scripts must be present in:
#     /scratch/users/k20009014
# - `set -eu` stops the script if a command fails or an undefined variable is
#   used.
# =============================================================================


# Stop if a command fails or an undefined variable is referenced.
set -eu


# -------------------------------------------------------------------------
# Move to the directory containing the six pipeline submission scripts
# -------------------------------------------------------------------------

cd /scratch/users/k20009014


# -------------------------------------------------------------------------
# Submit each processing stage with sequential SLURM dependencies
# -------------------------------------------------------------------------

# Submit the first structural preprocessing stage and store its job ID.
echo "Submitting PreFreeSurfer..."
jid1=$(sbatch --parsable 01_prefreesurfer_array.sh)
echo "PreFreeSurfer job: $jid1"

# Submit FreeSurfer only after PreFreeSurfer completes successfully.
echo "Submitting FreeSurfer after PreFreeSurfer..."
jid2=$(sbatch --parsable --dependency=afterok:$jid1 02_freesurfer_array.sh)
echo "FreeSurfer job: $jid2"

# Submit PostFreeSurfer only after FreeSurfer completes successfully.
echo "Submitting PostFreeSurfer after FreeSurfer..."
jid3=$(sbatch --parsable --dependency=afterok:$jid2 03_postfreesurfer_array.sh)
echo "PostFreeSurfer job: $jid3"

# Submit volumetric fMRI preprocessing after PostFreeSurfer succeeds.
echo "Submitting fMRIVolume after PostFreeSurfer..."
jid4=$(sbatch --parsable --dependency=afterok:$jid3 04_fmrivolume_array.sh)
echo "fMRIVolume job: $jid4"

# Submit surface-based fMRI processing after fMRIVolume succeeds.
echo "Submitting fMRISurface after fMRIVolume..."
jid5=$(sbatch --parsable --dependency=afterok:$jid4 05_fmrisurface_array.sh)
echo "fMRISurface job: $jid5"

# Submit MELODIC ICA after the surface-processing stage succeeds.
echo "Submitting MELODIC after fMRISurface..."
jid6=$(sbatch --parsable --dependency=afterok:$jid5 06_melodic_array.sh)
echo "MELODIC job: $jid6"


# -------------------------------------------------------------------------
# Print a summary of all submitted job IDs
# -------------------------------------------------------------------------

echo ""
echo "Pipeline submitted."
echo "PreFS:      $jid1"
echo "FS:         $jid2"
echo "PostFS:     $jid3"
echo "fMRIVol:    $jid4"
echo "fMRISurf:   $jid5"
echo "MELODIC:    $jid6"
