# Project Status

**Handoff record date:** 2026-10-06

## 1. Project objective

Use BayesPrism to deconvolve TCGA-BRCA bulk RNA-seq with a breast cancer scRNA-seq reference, assess deconvolution quality and validity, and perform downstream biological and statistical analyses leading to publication-quality figures and summary tables.

## 2. Current handoff state

Repository and reproducibility infrastructure are established. Stage 01 TCGA-BRCA acquisition and stage 02 TCGA bulk QC/structural validation are implemented and successfully executed.

`scripts/02_preprocess_tcga_bulk.R` has been reviewed, committed, pushed, and executed successfully. Production QC run `20261006T151501_23332` used acquisition run `20260915T222828_15620` and execution commit `ff27402350973c49a4e735c8a3f18a23082e68e3`. The committed run registry records this execution.

Stages 03–10 remain unimplemented. The breast cancer scRNA-seq reference remains unselected. BayesPrism remains uninstalled and unpinned for this project, and no deconvolution or downstream analysis has been performed.

The repository overview and workflow documentation are synchronized with the completed stage-02 state. This handoff summarizes current implementation and execution evidence without replacing the authoritative records listed below.

## 3. Repository state

| Item | State at handoff |
| --- | --- |
| Repository | BayesPrism-TCGA-BRCA |
| Current branch | `main` |
| HEAD | `cf0bd9dd7dc2775f8e22aef350825ab1f3cbc9ee` |
| HEAD message | Update README for completed TCGA QC stages |
| Local `main` versus `origin/main` | Synchronized; 0 ahead, 0 behind |
| Working tree | Clean |

Synchronization was verified against the locally recorded `origin/main` reference. No fresh fetch was performed during this handoff review.

Repository conventions:

- Large raw, processed, intermediate, and final biological data remain outside Git.
- Patient-level TCGA inputs, metadata, and diagnostic outputs remain outside Git.
- Machine-specific `config/local/paths.yml` and `.Renviron` are ignored.
- Numbered scripts reflect execution order and are created only when implemented.
- Failed samples or runs must never be silently discarded.

## 4. Implemented workflow

### 4.1 Stage 01 — TCGA-BRCA acquisition

**Script:** `scripts/01_acquire_tcga_bulk.R`  
**Status:** Implemented and successfully executed on 2026-09-15.  
**Acquisition run:** `20260915T222828_15620`  
**Execution Git commit:** `UNVERIFIED`; the exact execution commit was not recorded.

Acquisition uses NCI Genomic Data Commons / TCGA data with:

- Project: TCGA-BRCA
- Category: Transcriptome Profiling
- Type: Gene Expression Quantification
- Workflow: STAR - Counts
- Experimental strategy: RNA-Seq
- Access: open
- Final cohort sample type: Primary Tumor
- Retained expression assay: `unstranded` raw counts

The discovery query includes Primary Tumor and Solid Tissue Normal samples. Unique discovery patient IDs are intersected with IDs in the external `TCGA-sTIL_scoring.csv`; the resulting patients are queried for Primary Tumor samples.

This sTIL-based cohort restriction is provisional pending collaborator confirmation. No normalization, transformation, or gene filtering occurs during acquisition.

The successful acquisition counts recorded in [docs/analytical_decisions.md](docs/analytical_decisions.md) are:

| Quantity | Count |
| --- | ---: |
| RNA-seq discovery patients | 1,095 |
| Unique sTIL IDs | 854 |
| Overlapping/requested patients | 853 |
| Recovered patients | 853 |
| Recovered Primary Tumor samples | 869 |
| Genes | 60,660 |
| Patients with multiple Primary Tumor samples | 11 |

These counts describe the current provisional cohort, not necessarily the final publication cohort. The prior acquisition review reported no requested patients missing; that acquisition-specific result was not independently rechecked during this handoff review.

External output categories are:

- **Raw:** Immutable downloaded GDC source files under `raw/tcga_brca/`.
- **Processed:** Derived raw-count CSV, sample metadata CSV, and acquisition `SummarizedExperiment`, organized by acquisition run.
- **Intermediate:** Run-specific queries, manifests, identifier-specific diagnostic reports, provenance, session information, and acquisition log.

The current acquisition script writes aggregate-only log entries and retains identifier-specific CSV reports externally. These logging safeguards were added after the successful acquisition; they do not retrospectively sanitize its original log.

### 4.2 Stage 02 — TCGA bulk QC and structural validation

**Script:** `scripts/02_preprocess_tcga_bulk.R`  
**Status:** Implemented and successfully executed.  
**Production QC run:** `20261006T151501_23332`  
**Input acquisition run:** `20260915T222828_15620`  
**Execution Git commit:** `ff27402350973c49a4e735c8a3f18a23082e68e3`

The script:

- Selects the acquisition input explicitly through `tcga_acquisition_run_id`.
- Uses only the native `unstranded` assay in gene-by-sample orientation.
- Validates object structure, metadata alignment, identifiers, and raw counts.
- Calculates sample and gene QC.
- Reports multiple samples per patient without selecting or collapsing samples.
- Records input/script checksums, software versions, UTC timestamps, and Git provenance.
- Writes aggregate-only logs and external identifier-specific QC tables.

No expression normalization, transformation, filtering, transposition, identifier conversion, or expression-data rewriting occurs.

All stage-02 outputs remain external to Git under the configured intermediate root:

```text
tcga_brca/20260915T222828_15620/02_preprocess/20261006T151501_23332/
```

## 5. Current TCGA expression/QC state

### Production-validated structure and diagnostics

The finalized stage-02 summary and QC tables support the following observations:

| Property | Observed state |
| --- | --- |
| Object class | `RangedSummarizedExperiment` |
| Assay | `unstranded` |
| Orientation | Gene by sample |
| Genes | 60,660 |
| Samples | 869 |
| Unique patients | 853 |
| Sample types | All 869 samples are Primary Tumor |
| Raw-count validation | Numeric, integer-like, non-missing, finite, non-negative |
| Zero-total samples | 0 |
| Missing sample IDs | 0 |
| Duplicated sample-ID rows | 0 |
| Missing patient IDs | 0 |
| Patients with multiple samples | 11 |
| Maximum samples per patient | 3 |
| All-zero genes | 2,671 |
| Missing `gene_id` | 0 |
| Duplicated `gene_id` rows | 0 |
| Missing `gene_name` | 0 |
| Duplicated `gene_name` rows | 1,343 |
| Distinct duplicated `gene_name` values | 110 |
| Missing `gene_type` | 0 |
| Ensembl numeric-version-suffix count | 60,616 |
| Numeric-version-suffix proportion | Approximately 0.999275 |

The earlier exploratory inspection counted **1,233 duplicate gene-name occurrences beyond the first instance**. Production QC flags **all 1,343 rows participating in duplicated names**, spanning **110 distinct names**. These definitions are consistent: `1,343 − 110 = 1,233`.

The suffix diagnostic detects a terminal dot followed by digits; it does not strip suffixes or independently validate the Ensembl namespace.

All 60,660 genes have recorded `gene_type` values. The external gene QC table retains the original annotations and supports the full distribution; the YAML summary groups unrecognized annotation labels into a controlled aggregate category.

### Production QC summaries

| Measure | Minimum | Median | Mean | Maximum |
| --- | ---: | ---: | ---: | ---: |
| Library size | 19,225,117 | 57,196,716 | 57,564,906.217 | 114,015,705 |
| Detected genes per sample | 24,722 | 32,667 | 32,746.244 | 54,681 |
| Detected-gene proportion | 0.407550280 | 0.538526212 | 0.539832574 | 0.901434224 |
| Non-zero samples per gene | 0 | 491 | 469.115 | 869 |

All-zero genes, duplicate gene names, and multiple samples remain present. No automatic exclusions or analytical thresholds were introduced.

## 6. Confirmed methodological decisions

Acquisition decisions are recorded in [docs/analytical_decisions.md](docs/analytical_decisions.md). The implemented stage-02 scope also reflects the agreed project specification.

**Confirmed project decisions:**

- Preserve raw `unstranded` counts.
- Do not normalize or log-transform counts before BayesPrism.
- Stage 02 performs QC and structural validation only.
- Stage 02 does not remove genes or samples, strip Ensembl suffixes, resolve duplicate symbols, or transpose the matrix.
- Stage 05 owns gene-identifier harmonization.
- Stage 06 owns BayesPrism-specific input preparation.
- Select acquisition inputs explicitly using `tcga_acquisition_run_id`; do not automatically select the latest run.
- Do not create another complete expression matrix or `SummarizedExperiment` merely for stage-02 QC.

The selector is a documented placeholder in `config/paths.example.yml`; its actual value belongs in ignored local configuration.

**BayesPrism expectations from the prior methodological review:**

Raw unnormalized counts are the intended input, and the eventual bulk mixture uses sample-by-gene orientation. Transposition therefore belongs to input preparation. Multiple samples from one patient are not inherently a BayesPrism technical input violation.

The prior version-specific requirements review remains discussion-confirmed rather than a committed requirements-review artifact. Its official documentation and code references should be retained and checked when BayesPrism is pinned and input preparation is implemented.

## 7. Planned script sequence

| Stage | Description | Current status |
| --- | --- | --- |
| 01 | TCGA-BRCA acquisition | Implemented and successfully executed |
| 02 | TCGA bulk QC and structural validation | Implemented and successfully executed |
| 03 | Breast cancer scRNA-seq reference acquisition | Planned; reference not selected |
| 04 | scRNA-seq reference preprocessing | Planned; QC, annotation, and filtering pending |
| 05 | Gene identifier harmonization | Planned; identifier and duplicate handling pending |
| 06 | BayesPrism input preparation | Planned; implementation and final cleanup choices pending |
| 07 | BayesPrism deconvolution | Planned; software not installed or pinned |
| 08 | Deconvolution QC and validation | Planned |
| 09 | Downstream analyses | Planned |
| 10 | Figures and summary tables | Planned |

Stages 03–10 remain unimplemented. Stage numbering follows [docs/workflow.md](docs/workflow.md). No empty analysis scripts should be pre-created.

## 8. Stage-02 implementation and execution status

The reviewed script is committed and pushed. Its first production execution completed with observed process exit code **0** and finalized `qc_status: succeeded`.

### Execution provenance

| Field | Recorded value |
| --- | --- |
| QC run ID | `20261006T151501_23332` |
| Acquisition run ID | `20260915T222828_15620` |
| Execution Git commit | `ff27402350973c49a4e735c8a3f18a23082e68e3` |
| Git tree at execution | `clean` |
| Checksum algorithm | MD5 |
| Input RDS MD5 | `8cb414f572e34a0a70b65fe938360244` |
| Script MD5 | `dd8be6061b20c9889bc316a322edfb95` |
| UTC start | `2026-10-06T15:14:56Z` |
| UTC completion | `2026-10-06T15:15:14Z` |
| R | 4.4.3 |
| SummarizedExperiment | 1.34.0 |
| yaml | 2.3.12 |

The committed [metadata/run_registry.tsv](metadata/run_registry.tsv) records this successful execution and its exact Git commit.

### Finalized external artifacts

```text
sample_qc.tsv
gene_qc.tsv
multiple_samples_per_patient.tsv
qc_summary.yml
session_info.txt
preprocess_tcga_bulk.log
```

All six files exist and are non-empty. The finalized summary records all required outputs as completed, and no `.tmp` files remain. QC tables contain 869 sample rows, 60,660 gene rows, and 11 multiple-sample report rows.

TSVs use UTF-8, quoted character fields, and `<QC_MISSING>` as the missing-value sentinel. Literal `"NA"` is preserved as a character value.

The log records passing validation and points to `qc_summary.yml` as the final completion marker. Identifier-specific QC remains external. No expression matrix or RDS was exported.

### Warnings and execution context

The production execution had **0 script QC warnings** and **0 output/finalization warnings**.

Startup diagnostics included `C.UTF-8` locale-setting warnings and a renv diagnostic that `BiocManager` loaded before activation. These were observed during the production execution review and summarized in the run registry; startup diagnostics are not included in the script's QC warning count.

These diagnostics did not prevent successful execution or output finalization.

## 9. Unresolved scientific and analytical decisions

### Cohort — provisional

The sTIL-based restriction awaits collaborator confirmation. The scoring dataset’s original provenance, publication, access conditions, and eligibility criteria remain unverified.

### Multiple Primary Tumor samples — unresolved

Production QC confirms that 11 patients have multiple samples: 6 patients have two samples and 5 have three, with a maximum of three.

No samples were selected, removed, or aggregated. Handling remains unresolved for downstream analyses requiring independent patient-level observations and must be documented before those analyses.

### scRNA-seq reference — pending

The reference dataset remains unselected. Approved reference-selection criteria are recorded in [docs/scrna_reference_selection.md](docs/scrna_reference_selection.md). Candidate assessment, Stage-04 QC and annotation, donor coverage, and filtering decisions remain pending.

### Gene harmonization — pending

Ensembl version-suffix handling and duplicate-symbol resolution remain undecided. The final canonical identifier strategy depends on the selected reference.

### BayesPrism — pending

BayesPrism is not installed or version-pinned for this project. Final cleanup, filtering, and model parameters remain undecided. Protein-coding-only filtering has not been adopted as a project rule.

## 10. Computational environment

| Component | Confirmed version or state |
| --- | --- |
| Local platform | Windows x86_64 |
| R | 4.4.3 |
| Bioconductor release | 3.19 |
| renv | 1.2.4 |
| TCGAbiolinks | 2.32.0 |
| SummarizedExperiment | 1.34.0 |
| yaml | 2.3.12 |
| Dependency record | Committed `renv.lock` |
| Last documented renv status check | “No issues found -- the project is in a consistent state.” |
| BayesPrism | Not installed or version-pinned for this project |

`renv` was initialized after acquisition. Its committed lockfile records the project dependency environment. Stage-02 provenance confirms R and the directly used SummarizedExperiment/yaml versions; the last documented renv consistency check is not a fresh status assessment.

Normal renv sandbox activation hangs in the local Windows environment. An ignored, machine-specific `.Renviron` uses:

```text
RENV_CONFIG_SANDBOX_ENABLED=FALSE
```

This workaround is not committed and is not a cross-platform requirement. Other environments should use the default sandbox unless independently shown to require the workaround.

HPC software versions, system libraries, scheduler settings, and resource requirements remain unconfirmed. Consult [docs/environment.md](docs/environment.md) for detailed environment records.

## 11. Data and provenance records

| Record | Authoritative role |
| --- | --- |
| [AGENTS.md](AGENTS.md) | Scientific integrity, data protection, coding, and Git rules |
| [metadata/data_sources.tsv](metadata/data_sources.tsv) | Dataset provenance, releases, retrieval dates, intended uses, and unresolved source details |
| [metadata/run_registry.tsv](metadata/run_registry.tsv) | Compact registry of actual execution attempts, input runs, statuses, and execution Git commits |
| [docs/analytical_decisions.md](docs/analytical_decisions.md) | Confirmed, provisional, and pending analytical decisions and acquisition counts |
| [docs/scrna_reference_selection.md](docs/scrna_reference_selection.md) | Approved reference-selection criteria and future candidate assessment framework |
| [docs/workflow.md](docs/workflow.md) | Workflow ordering, inputs/outputs, and data-location conventions |
| [docs/environment.md](docs/environment.md) | Computational environment and local versus HPC considerations |
| [renv.lock](renv.lock) | Machine-readable dependency versions and sources |
| [config/paths.example.yml](config/paths.example.yml) | Safe configuration schema and explicit acquisition-run selector |
| [scripts/01_acquire_tcga_bulk.R](scripts/01_acquire_tcga_bulk.R) | Implemented acquisition behavior |
| [scripts/02_preprocess_tcga_bulk.R](scripts/02_preprocess_tcga_bulk.R) | Implemented bulk QC, validation, output handling, and provenance behavior |
| [README.md](README.md) | Concise public-facing scientific overview of the repository |

The dataset provenance record identifies TCGA input as **GDC Data Release 46.0**, retrieved on **2026-09-15**. sTIL source details and the scRNA-seq reference remain unresolved.

The run registry records stage 01 with `git_commit = UNVERIFIED` and stage 02 with its exact execution commit. Future actual attempts should be registered after their outcomes are inspected, including failed, interrupted, and incomplete runs. Planned work does not receive execution rows.

External provenance, logs, manifests, and QC reports provide detailed execution evidence and may contain identifiers or private paths. They must remain outside Git.

`PROJECT_STATUS.md` is a handoff snapshot, not a replacement for these records. When records conflict, inspect the implementation and execution evidence and update the appropriate detailed record explicitly.

## 12. Immediate next action

Use the approved criteria in [docs/scrna_reference_selection.md](docs/scrna_reference_selection.md) to assess candidate breast cancer scRNA-seq references before selecting a dataset or creating stage-03 implementation code.

No breast cancer scRNA-seq reference has yet been selected, and no stage-03 script has been created.

## 13. Handoff rules

- Read `PROJECT_STATUS.md` first, then consult the authoritative detailed records.
- Preserve the distinction between repository-backed facts, external execution evidence, discussion-confirmed observations, provisional decisions, and planned work.
- Do not commit patient-level data or large expression matrices.
- Do not modify raw data.
- Do not silently filter or exclude samples or genes.
- Distinguish planned, implemented, and successfully executed work.
- Inspect logs, expected outputs, and QC before declaring success.
- Record actual execution outcomes, including failures, in the run registry.
- Update this handoff when project state materially changes; Git history remains the historical record.

---

Verification note: Repository branch, HEAD, message, clean working tree, and synchronization with the local remote-tracking reference were verified during the handoff review. Finalized stage-02 external outputs independently support the production QC findings, aggregate summaries, provenance, and output finalization. The stage-01 execution Git commit remains `UNVERIFIED`, and the earlier acquisition-specific claim of zero requested patients missing was not independently rechecked. The BayesPrism requirements review remains discussion-confirmed rather than a committed requirements-review artifact. Production exit code 0 and detailed startup diagnostics were observed during the earlier execution review, not stored as dedicated fields in the finalized QC summary. BayesPrism’s uninstalled/unpinned state reflects documented project state; no fresh installation scan was performed. No fresh fetch, new analysis execution, or acquisition-input reload was performed during the handoff review. Only `PROJECT_STATUS.md` was modified when applying this revision.
