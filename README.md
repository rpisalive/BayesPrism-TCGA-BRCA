# BayesPrism-TCGA-BRCA

Reproducible workflows, scripts, and findings for BayesPrism-based deconvolution of TCGA-BRCA bulk RNA-seq using breast cancer single-cell RNA-seq references, followed by downstream tumor and tumor microenvironment analyses.

## Project overview

Bulk RNA-seq measurements from tumor samples represent mixtures of malignant cells and multiple non-malignant cell populations within the tumor microenvironment. Computational deconvolution can be used to estimate the cellular composition of these samples and recover cell-type-specific transcriptional information.

This project uses **BayesPrism** to deconvolve bulk RNA-seq data from **The Cancer Genome Atlas Breast Invasive Carcinoma cohort (TCGA-BRCA)** using a breast cancer **single-cell RNA-seq reference dataset**.

The repository documents the complete analysis workflow, including data preprocessing, reference construction, BayesPrism deconvolution, quality assessment, downstream analyses, and interpretation of results.

## Objectives

The main objectives of this project are to:

1. Prepare and quality-control TCGA-BRCA bulk RNA-seq data for deconvolution.
2. Construct an appropriate breast cancer single-cell RNA-seq reference for BayesPrism.
3. Estimate cell-type proportions in TCGA-BRCA tumor samples using BayesPrism.
4. Evaluate the robustness and biological plausibility of the deconvolution results.
5. Investigate tumor and tumor-microenvironment characteristics derived from the deconvolution.
6. Perform downstream analyses to identify biologically and clinically relevant patterns associated with breast cancer heterogeneity.

Additional analyses will be incorporated as the project develops.

## Analysis workflow

The planned workflow is:

```text
Breast cancer scRNA-seq reference
            |
            v
   Reference preprocessing
            |
            v
Cell-type annotation / filtering
            |
            |
            +-----------------------------+
                                          |
TCGA-BRCA bulk RNA-seq                    |
            |                             |
            v                             |
    Bulk data preprocessing               |
            |                             |
            +-------------+---------------+
                          |
                          v
                    BayesPrism
                          |
              +-----------+-----------+
              |                       |
              v                       v
      Cell-type fractions      Cell-type-specific
                               expression estimates
              |                       |
              +-----------+-----------+
                          |
                          v
                 Quality assessment
                          |
                          v
                 Downstream analyses
                          |
                          v
              Biological interpretation
```

## Data sources

### TCGA-BRCA bulk RNA-seq

Bulk transcriptomic data will be obtained from the **TCGA Breast Invasive Carcinoma (TCGA-BRCA)** cohort.

Associated clinical and molecular metadata may also be incorporated where appropriate for downstream analyses.

### Single-cell RNA-seq reference

A breast cancer single-cell RNA-seq dataset will be used as the reference for BayesPrism deconvolution.

Reference preprocessing will include, where appropriate:

* quality control;
* gene filtering;
* cell-type annotation review;
* removal or consolidation of unsuitable cell populations;
* harmonization of gene identifiers between the single-cell and bulk datasets;
* preparation of the expression matrix and cell-type labels required by BayesPrism.

Details of the selected reference dataset and preprocessing decisions will be documented as the project progresses.

## Repository structure

The repository is intended to contain analysis code, documentation, selected summary results, and figures.

A provisional structure is:

```text
BayesPrism-TCGA-BRCA/
|
├── README.md
├── scripts/
│   ├── 01_data_preparation/
│   ├── 02_reference_preprocessing/
│   ├── 03_bulk_preprocessing/
│   ├── 04_bayesprism/
│   ├── 05_deconvolution_qc/
│   └── 06_downstream_analysis/
|
├── config/
|
├── metadata/
|
├── results/
│   ├── qc/
│   ├── deconvolution/
│   ├── downstream/
│   └── tables/
|
├── figures/
|
└── docs/
```

The directory structure may be modified as the analysis develops.

## Reproducibility

The analysis will be developed as a reproducible computational workflow.

Where possible, the repository will document:

* software and package versions;
* preprocessing parameters;
* filtering criteria;
* BayesPrism parameters;
* random seeds where relevant;
* input and output file relationships;
* major analytical decisions.

Environment information and package dependencies will be added once the computational environment has been finalized.

## Data management

Large expression matrices and controlled-access or patient-level datasets will **not** be stored directly in this repository.

The repository will primarily contain:

* analysis scripts;
* configuration files;
* documentation;
* non-sensitive metadata where appropriate;
* summary tables;
* figures;
* derived results suitable for version control.

Local or HPC paths to large datasets will be excluded from version control where necessary.

## BayesPrism

BayesPrism is a Bayesian framework for decomposing bulk transcriptomic profiles using single-cell reference data.

In this project, BayesPrism will be used to infer the cellular composition of TCGA-BRCA bulk tumors and, where appropriate, obtain cell-type-specific transcriptional estimates for subsequent analyses.

BayesPrism repository:

https://github.com/Danko-Lab/BayesPrism

## Project status

**Current status:** Project setup and analysis planning.

Planned initial stages:

* [ ] Obtain and organize TCGA-BRCA bulk RNA-seq data
* [ ] Obtain and inspect the breast cancer scRNA-seq reference
* [ ] Define cell-type annotation strategy
* [ ] Harmonize gene identifiers across datasets
* [ ] Perform reference quality control
* [ ] Perform bulk RNA-seq preprocessing
* [ ] Prepare BayesPrism input objects
* [ ] Run initial BayesPrism deconvolution
* [ ] Evaluate deconvolution quality
* [ ] Develop downstream analysis workflow

This section will be updated as the project progresses.

## Documentation of findings

In addition to analysis scripts, this repository will be used to document important analytical observations, parameter choices, limitations, and biological findings.

Major decisions and results will be recorded so that the development of the analysis can be reviewed and discussed with collaborators and supervisors.
