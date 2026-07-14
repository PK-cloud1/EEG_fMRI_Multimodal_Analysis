# EEG–fMRI Multimodal Analysis of Epileptic Activity

This repository contains the analysis pipelines developed for my MSc research project investigating the characterisation of epileptic activity using complementary electroencephalography (EEG) and functional magnetic resonance imaging (fMRI) analyses.

The project combines automated spike-and-wave discharge (SWD) detection from EEG with independent component analysis (ICA) of fMRI data and temporal correlation of generalised spike-and-wave (GSW) events with functional brain networks.

This project accompanies my MSc dissertation at King's College London.

---

## Key Components

- **Automated SWD Detection:** Extraction of temporal and spectral EEG features and support vector machine (SVM) classification of SWD and non-SWD activity.
- **fMRI Processing and ICA:** Structural and functional MRI preprocessing using the Human Connectome Project (HCP) Pipelines, followed by independent component analysis using FSL MELODIC.
- **Multimodal Correlation Analysis:** Temporal correlation of HRF-convolved EEG-derived GSW events with ICA component time courses.

---

## Analysis Workflow

### 1. Automated GSW Detection Pipeline

EEG recordings were processed to identify and classify epileptic activity.

The workflow includes:

- Annotation of SWD events from EEG marker files
- Extraction of balanced 2-second SWD and non-SWD epochs
- Extraction of temporal features:
  - Mean
  - Standard deviation
  - Maximum
  - Minimum
  - Root mean square (RMS)
- Extraction of spectral power in the:
  - Delta band (1–4 Hz)
  - Theta band (4–8 Hz)
  - Alpha band (8–13 Hz)
  - Beta band (13–30 Hz)
- Exploratory principal component analysis (PCA)
- RBF support vector machine classification
- Group-aware train/test splitting by EEG recording
- Evaluation using classification metrics, confusion matrices and ROC AUC

### 2. MRI Processing

Structural and functional MRI data were processed using the HCP Pipelines.

The workflow consists of:

1. PreFreeSurfer
2. FreeSurfer
3. PostFreeSurfer
4. fMRIVolume
5. fMRISurface
6. FSL MELODIC ICA

Surface registration was performed using MSMSulc. MELODIC was subsequently used to decompose the preprocessed fMRI time series into spatially independent components and their associated temporal time courses.

The HCP processing stages were executed as SLURM array jobs using Singularity containers on a high-performance computing cluster.

### 3. GSW–ICA Correlation Analysis

EEG-derived GSW timings were compared with the temporal activity of fMRI ICA components.

For each subject and functional run:

- GSW onset and duration values were extracted from EEG marker files
- Event timings were aligned to the fMRI temporal resolution
- A binary GSW event vector was constructed
- The event vector was convolved with a canonical haemodynamic response function (HRF)
- Pearson correlation was calculated between the predicted GSW-related BOLD response and each ICA component time course
- Components were ranked by absolute correlation strength
- The five strongest component associations per run were retained for comparison with visually assigned functional network labels

---

## Project Structure

    EEG_fMRI_Multimodal_Analysis/
    │
    ├── Automated_GSW_detection_pipeline/
    │   ├── EEG_annotation_.ipynb
    │   ├── EPOCHS_.ipynb
    │   ├── FEATURES_.ipynb
    │   └── SVM_FINAL_.ipynb
    │
    ├── MRI processing/
    │   ├── 01_prefreesurfer_array_.sh
    │   ├── 02_freesurfer_array_.sh
    │   ├── 03_postfreesurfer_array_.sh
    │   ├── 04_fmrivolume_array_.sh
    │   ├── 05_fmrisurface_array_.sh
    │   ├── 06_melodic_array_.sh
    │   └── submit_full_pipeline_.sh
    │
    ├── Correlation Analysis/
    │   └── group_gsw_ic_correlation_.ipynb
    │
    └── README.md

---

## How to Run

The analysis should be performed in the following order:

1. Run the notebooks in `Automated_GSW_detection_pipeline/` to annotate EEG events, extract epochs and features, and train and evaluate the SVM classifier.
2. Submit `submit_full_pipeline.sh` to execute the HCP preprocessing and MELODIC ICA workflow in the required order.
3. Run `group_gsw_ic_correlation.ipynb` after MELODIC outputs and EEG marker files are available.

> **Note:** File paths within the scripts reflect the directory structure used during the original analysis and may require modification before execution in another computing environment.

---

## Software and Computational Environment

The analyses were performed using Python, MNE-Python, NumPy, SciPy, scikit-learn, pandas, FSL MELODIC, the HCP Pipelines, FreeSurfer, Connectome Workbench and Singularity.

HCP preprocessing was performed on a SLURM-managed high-performance computing cluster.

Software versions and detailed processing parameters are reported in the Methods section of the accompanying dissertation.

---

## Data Availability

The EEG and fMRI datasets used in this project are not included in this repository.

This repository contains the analysis scripts required to reproduce the computational workflow where the appropriate input data and computing environment are available.

---

## Citation

If you use or adapt code from this repository, please cite:

> Kusi-Yeboah, P. (2026). Investigating Epileptic Activity Through Machine Learning and Multimodal EEG-fMRI Analysis . Master's dissertation, King's College London.
