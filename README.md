# BayesPrism-TCGA-BRCA

Reproducible workflows and documentation for preparing TCGA-BRCA bulk RNA-seq for BayesPrism deconvolution with a breast cancer single-cell RNA-seq reference, followed by deconvolution quality assessment and downstream biological and statistical analyses.

## Project overview

Bulk tumor RNA-seq measures a mixture of malignant and non-malignant cell populations. This project will use BayesPrism to estimate the cellular composition of TCGA-BRCA bulk tumors using a breast cancer single-cell RNA-seq reference.

The project currently has a successfully executed TCGA-BRCA acquisition stage and a successfully executed bulk QC and structural-validation stage. The single-cell reference has not yet been selected, BayesPrism has not yet been installed or version-pinned, and no deconvolution or downstream analysis has been performed.

## Objectives

1. Prepare and quality-control TCGA-BRCA bulk RNA-seq for deconvolution.
2. Select and construct an appropriate breast cancer scRNA-seq reference.
3. Perform BayesPrism deconvolution of TCGA-BRCA tumors.
4. Evaluate deconvolution quality and biological plausibility.
5. Investigate tumor and tumor-microenvironment features using the inferred cellular and transcriptional profiles.
6. Develop reproducible downstream analyses suitable for publication.

## Current workflow status

| Stage | Status |
| --- | --- |
| 01. TCGA-BRCA acquisition | Implemented and successfully executed |
| 02. TCGA bulk QC and structural validation | Implemented and successfully executed |
| 03. Breast cancer scRNA-seq reference acquisition | Planned |
| 04. scRNA-seq reference preprocessing | Planned |
| 05. Gene identifier harmonization | Planned |
| 06. BayesPrism input preparation | Planned |
| 07. BayesPrism deconvolution | Planned |
| 08. Deconvolution QC and validation | Planned |
| 09. Downstream analyses | Planned |
| 10. Figures and summary tables | Planned |

The current TCGA-BRCA cohort is provisionally restricted to patients represented in an external `TCGA-sTIL_scoring.csv` file. This cohort rule remains subject to collaborator confirmation and should not be treated as the final study-cohort definition.

## Implemented scripts

### `scripts/01_acquire_tcga_bulk.R`

This script acquires the provisional sTIL-matched TCGA-BRCA Primary Tumor cohort from the NCI Genomic Data Commons using open-access STAR - Counts RNA-seq data. It retains the `unstranded` assay as raw counts and does not normalize, transform, or filter expression values during acquisition.

### `scripts/02_preprocess_tcga_bulk.R`

This script performs deterministic QC and structural validation for one explicitly selected acquisition run. It validates the acquisition object, the `unstranded` assay, metadata alignment, identifiers, and raw counts; calculates sample and gene QC; and records aggregate provenance and validation results.

It does not normalize, log-transform, filter, transpose, convert identifiers, collapse duplicate gene symbols, select one sample per patient, run BayesPrism, or write another expression matrix or `SummarizedExperiment`.

Its first production run completed successfully for the current acquisition cohort, validating 60,660 genes, 869 Primary Tumor samples, and 853 patients. Detailed QC outputs remain external to Git.

## Data management and reproducibility

Large biological data remain outside Git:

- Raw, processed, intermediate, and final biological data are stored under configured external data roots.
- Patient-level TCGA data, expression matrices, and identifier-bearing QC outputs are not committed.
- Raw inputs are immutable.
- Machine-specific paths belong in ignored `config/local/paths.yml`.
- Local environment workarounds belong in ignored machine-specific configuration.
- Sample, cell, or gene exclusions must be documented and must not occur silently.

The repository contains scripts, safe configuration examples, documentation, small non-sensitive metadata, execution records, and reproducibility infrastructure. The committed `renv.lock` records the project R dependency environment.

## Repository layout

```text
BayesPrism-TCGA-BRCA/
├── README.md
├── PROJECT_STATUS.md
├── AGENTS.md
├── .gitignore
├── .Rprofile
├── renv.lock
├── renv/
├── config/
│   └── paths.example.yml
├── docs/
│   ├── analytical_decisions.md
│   ├── environment.md
│   └── workflow.md
├── metadata/
│   ├── data_sources.tsv
│   └── run_registry.tsv
└── scripts/
    ├── 01_acquire_tcga_bulk.R
    └── 02_preprocess_tcga_bulk.R
```

Additional numbered scripts will be created only when their inputs, parameters, and outputs have been agreed.

## Documentation and provenance

- [PROJECT_STATUS.md](PROJECT_STATUS.md) — current project handoff state and concise execution summary.
- [docs/workflow.md](docs/workflow.md) — workflow stages, inputs, outputs, and data-location conventions.
- [docs/analytical_decisions.md](docs/analytical_decisions.md) — confirmed, provisional, and pending analytical decisions.
- [docs/environment.md](docs/environment.md) — current computational environment and local/HPC considerations.
- [metadata/data_sources.tsv](metadata/data_sources.tsv) — dataset provenance and unresolved source details.
- [metadata/run_registry.tsv](metadata/run_registry.tsv) — compact registry of actual execution attempts, statuses, input runs, and Git commits.

Detailed execution artifacts, including logs, provenance, and identifier-bearing QC tables, remain external to Git.

## BayesPrism status

BayesPrism has not yet been installed, configured, or version-pinned for this project. Its installation source, version, input requirements, reference composition, filtering decisions, and model parameters will be documented before the first deconvolution run.

Official BayesPrism repository: <https://github.com/Danko-Lab/BayesPrism>
