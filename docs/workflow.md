# Workflow

**Workflow record date:** 2026-10-06  
**Scope:** This document describes the implemented TCGA-BRCA acquisition and bulk QC stages and the planned analysis sequence for BayesPrism deconvolution. Analytical choices and unresolved decisions are recorded in [`docs/analytical_decisions.md`](analytical_decisions.md).

## Data-location convention

Code, non-sensitive configuration examples, documentation, small metadata files, summary tables, and appropriate figures are version controlled in Git.

Machine-specific paths are stored in the ignored `config/local/paths.yml` file. Large biological inputs, patient-level data, expression matrices, and run outputs remain outside Git under the configured external project data root.

External data are organized as:

```text
raw/           Immutable source data
processed/     Derived processed data
intermediate/  Run-specific logs, provenance, and QC artifacts
final/         Final analysis outputs
```

Raw inputs are not modified. Derived files are written to processed, intermediate, or final locations according to their role.

## Execution order

```text
External sTIL scoring CSV ─┐
                           ├─> 01 TCGA-BRCA acquisition [implemented]
GDC TCGA-BRCA data ────────┘
                                     |
                                     v
             02 TCGA bulk QC and structural validation [implemented]
                                     |
Breast cancer scRNA-seq reference ──┼─> Reference acquisition and preprocessing [planned]
                                     |
                                     v
                      Gene identifier harmonization [planned]
                                     |
                                     v
                       BayesPrism input preparation [planned]
                                     |
                                     v
                         BayesPrism deconvolution [planned]
                                     |
                                     v
                     Deconvolution QC and validation [planned]
                                     |
                                     v
             Downstream analyses, figures, and summary tables [planned]
```

Scripts 01 and 02 are implemented. Later numbered scripts will be added only when their inputs, parameters, and outputs have been agreed and implemented.

## 01. TCGA-BRCA acquisition — implemented

**Script:** `scripts/01_acquire_tcga_bulk.R`

### Inputs

- External `TCGA-sTIL_scoring.csv`, specified in ignored local configuration.
- Open-access TCGA-BRCA RNA-seq data queried from the GDC.
- Machine-specific external storage locations from `config/local/paths.yml`.

### Process

1. Run a GDC discovery query for TCGA-BRCA Transcriptome Profiling, Gene Expression Quantification, STAR - Counts, RNA-Seq data.
2. Obtain unique patient IDs from the discovery query.
3. Intersect those IDs with IDs in `TCGA-sTIL_scoring.csv`.
4. Query the resulting cohort for Primary Tumor STAR - Counts data.
5. Download GDC source data to external raw storage.
6. Prepare a `SummarizedExperiment` and retain the `unstranded` assay as raw counts.
7. Validate count-matrix dimensions, values, identifiers, and alignment with gene and sample metadata.
8. Export derived raw-count and metadata files to external processed storage.
9. Write run-specific provenance, logs, manifests, and QC reports to external intermediate storage.

No normalization, transformation, or gene filtering occurs during this stage.

### Outputs

The implemented script writes the following categories of external artifacts:

- Immutable GDC source data in `raw/tcga_brca/`.
- Derived raw-count exports, metadata exports, and a `SummarizedExperiment` object in `processed/tcga_brca/`.
- Acquisition logs, provenance, session information, query records, manifests, and QC reports in `intermediate/tcga_brca/`.

Identifier-specific reports remain external and are not committed to Git. Acquisition logs record aggregate information only.

### Current run status

A TCGA-BRCA acquisition run completed successfully on 2026-09-15. It produced the current provisional sTIL-matched Primary Tumor cohort and associated external provenance and QC artifacts. Detailed run counts and unresolved cohort decisions are recorded in `docs/analytical_decisions.md`.

The sTIL-based cohort restriction remains provisional pending collaborator confirmation.

## 02. TCGA bulk QC and structural validation — implemented

**Script:** `scripts/02_preprocess_tcga_bulk.R`

This stage performs deterministic QC and structural validation of one acquisition run selected explicitly through `tcga_acquisition_run_id`. Machine-specific paths remain in ignored `config/local/paths.yml`.

### Production execution

- QC run ID: `20261006T151501_23332`
- Input acquisition run: `20260915T222828_15620`
- Execution Git commit: `ff27402350973c49a4e735c8a3f18a23082e68e3`
- `qc_status`: `succeeded`

### Inputs

- The acquisition `RangedSummarizedExperiment` selected through `tcga_acquisition_run_id`.
- Only its `unstranded` assay, retained in gene-by-sample orientation.
- External locations defined by ignored local configuration.

### Process

The script validates object and assay structure, rowData/colData alignment, and raw counts. It calculates sample and gene QC, diagnoses multiple samples per patient, records input and script checksums, records R/package/Git provenance, and writes aggregate-only logs.

It does not normalize or log-transform counts; filter genes or samples; transpose counts; strip Ensembl suffixes; convert identifiers; collapse duplicate gene symbols; select one sample per patient; run BayesPrism; or write another expression matrix or `SummarizedExperiment`.

### Outputs

Run-specific outputs remain outside Git under:

```text
intermediate/tcga_brca/<acquisition_run_id>/02_preprocess/<qc_run_id>/
```

- `sample_qc.tsv`
- `gene_qc.tsv`
- `multiple_samples_per_patient.tsv`
- `qc_summary.yml`
- `session_info.txt`
- `preprocess_tcga_bulk.log`

Identifier-bearing QC tables remain outside Git.

### Current production status

The successful production run validated 60,660 genes, 869 Primary Tumor samples, and 853 patients. It found 0 zero-total samples, 0 missing sample IDs, 0 duplicated sample-ID rows, and 0 missing patient IDs. Eleven patients had multiple samples. Gene diagnostics found 2,671 all-zero genes, 0 missing or duplicated `gene_id` rows, 1,343 rows participating in duplicated `gene_name` values across 110 distinct values, and 60,616 gene IDs with terminal numeric version suffixes. No genes or samples were removed.

For current handoff state, see [`PROJECT_STATUS.md`](../PROJECT_STATUS.md). For executed-run records, see [`metadata/run_registry.tsv`](../metadata/run_registry.tsv). For analytical decisions, see [`docs/analytical_decisions.md`](analytical_decisions.md).

## Planned stages

| Planned order | Stage | Current status |
| ------------- | ----- | -------------- |
| 02 | TCGA bulk QC and structural validation | Implemented and successfully executed. |
| 03 | Breast cancer scRNA-seq reference acquisition | Planned; reference dataset not yet selected. |
| 04 | scRNA-seq reference preprocessing | Planned; QC, annotation, and filtering decisions remain pending. |
| 05 | Gene identifier harmonization | Planned; identifier conventions and duplicate handling remain pending. |
| 06 | BayesPrism input preparation | Planned; requirements and parameters remain pending. |
| 07 | BayesPrism deconvolution | Planned; BayesPrism is not yet installed or version-pinned. |
| 08 | Deconvolution QC and validation | Planned; validation criteria remain pending. |
| 09 | Downstream analyses | Planned; analysis questions and statistical methods remain pending. |
| 10 | Figures and summary tables | Planned; outputs will be created after analytical results are reviewed. |

Each implemented stage should document its inputs, outputs, software environment, parameters, QC checks, and material analytical decisions before results are interpreted.
