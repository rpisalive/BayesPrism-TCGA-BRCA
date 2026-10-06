# Project Status

**Handoff record date:** 2026-10-06

## 1. Project objective

Use BayesPrism to deconvolve TCGA-BRCA bulk RNA-seq with a breast cancer scRNA-seq reference, assess deconvolution quality and validity, and perform downstream biological and statistical analyses leading to publication-quality figures and summary tables.

## 2. Current handoff state

Repository and reproducibility infrastructure are established. TCGA-BRCA acquisition is implemented and documented as successfully executed.

BayesPrism input requirements have been reviewed, the acquisition object has been structurally inspected, and the methodological specification for script 02 has been agreed in the project discussion. These review and specification details are not yet encoded in committed repository documents.

`scripts/02_preprocess_tcga_bulk.R` does not exist. The scRNA-seq reference remains unselected, and BayesPrism has not been installed or version-pinned. No deconvolution or downstream analysis has been executed.

The README retains an earlier setup status and provisional directory layout. The workflow document also predates the script-02 specification. Use the detailed records identified below for implemented work, with the separately labelled discussion-confirmed information in this handoff for subsequent planning.

## 3. Repository state

| Item | State at handoff |
| --- | --- |
| Repository | BayesPrism-TCGA-BRCA |
| Current branch | `main` |
| HEAD | `b582508ea3c34e6d227054bc985f2008c2f092c2` |
| HEAD message | Add explicit TCGA acquisition run selector |
| Local `main` versus `origin/main` | Synchronized with the locally recorded remote-tracking reference; 0 ahead, 0 behind |
| Working tree | Clean |

No fetch was performed for this handoff review; remote synchronization describes the current local Git references.

Repository conventions:

- Large raw, processed, intermediate, and final biological data remain outside Git.
- Patient-level TCGA inputs, metadata, and diagnostic outputs remain outside Git.
- Machine-specific `config/local/paths.yml` and `.Renviron` are ignored.
- Numbered scripts reflect execution order and are created only when implemented.
- Failed samples or runs must never be silently discarded.

## 4. Implemented workflow

### 4.1 Stage 01 — TCGA-BRCA acquisition

**Script:** `scripts/01_acquire_tcga_bulk.R`  
**Status:** Implemented; successful execution on 2026-09-15 is documented in the workflow and analytical-decision records.

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

The following successful-run counts are recorded in `docs/analytical_decisions.md`:

| Quantity | Count |
| --- | ---: |
| RNA-seq discovery patients | 1,095 |
| Unique sTIL IDs | 854 |
| Overlapping/requested patients | 853 |
| Recovered patients | 853 |
| Recovered Primary Tumor samples | 869 |
| Genes | 60,660 |
| Patients with multiple Primary Tumor samples | 11 |

The successful run ID, `20260915T222828_15620`, is confirmed in the project discussion but is not recorded in the inspected committed documentation. Prior run inspection reported 0 requested patients not recovered and 0 duplicated sample identifiers; these results are also not yet recorded in committed documentation.

External output categories are:

- **Raw:** Immutable downloaded GDC source files under `raw/tcga_brca/`.
- **Processed:** Derived raw-count CSV, sample metadata CSV, and acquisition `SummarizedExperiment`, organized by acquisition run.
- **Intermediate:** Run-specific queries, manifests, identifier-specific diagnostic reports, provenance, session information, and acquisition log.

The current script writes aggregate-only acquisition log entries and retains identifier-specific CSV reports externally. These logging safeguards were added after the successful run; they do not retrospectively sanitize its original log.

## 5. Current TCGA expression-object state

### Recorded in committed repository documentation

The successful acquisition retained the `unstranded` raw-count assay with 60,660 genes, 869 Primary Tumor samples, and 853 patients. Eleven patients have multiple samples. No samples were selected or collapsed during acquisition.

### Confirmed during pre-script-02 inspection; not yet encoded in a committed repository artifact

The prior structural inspection established:

| Property | Observed state |
| --- | --- |
| Object class | `RangedSummarizedExperiment` |
| Dimensions | 60,660 genes × 869 samples |
| Assay for subsequent bulk QC | `unstranded` |
| Values | Raw integer counts |
| Orientation | Gene by sample |
| Missing counts | 0 |
| Non-finite counts | 0 |
| Negative counts | 0 |
| Zero-total samples | 0 |
| All-zero genes | 2,671 |
| Required gene annotations | `gene_id`, `gene_name`, `gene_type` available |
| `gene_id` | Unique; most values retain Ensembl version suffixes |
| `gene_name` | Not unique |
| Unique patients | 853 |
| Patients with multiple samples | 11 |
| Sample types | All 869 samples are Primary Tumor |

These observations were not rechecked against external data during this handoff review. No patient-level data were inspected.

## 6. Confirmed methodological decisions

Acquisition decisions are recorded in `docs/analytical_decisions.md`. The following additional scope decisions were established in the pre-script-02 discussion and are recorded here for handoff.

**Project decisions:**

- Preserve raw `unstranded` counts.
- Do not normalize or log-transform counts before BayesPrism.
- Script 02 performs QC and structural validation only.
- Script 02 must not remove genes or samples, strip Ensembl version suffixes, resolve duplicate gene symbols, or transpose the matrix.
- Script 05 owns gene-identifier harmonization.
- Script 06 owns BayesPrism-specific input preparation.
- Select the acquisition input explicitly using `tcga_acquisition_run_id`; do not automatically select the latest run.
- Do not create another complete expression matrix or `SummarizedExperiment` merely for script-02 QC.

The explicit selector is present as a documented placeholder in `config/paths.example.yml`. Its actual value belongs in ignored local configuration.

**BayesPrism input expectations from the prior methodological review:**

Raw unnormalized counts are the intended input, and the eventual bulk mixture matrix uses sample-by-gene orientation. The transpose therefore belongs to input preparation, not script 02. Multiple samples from one patient are not inherently a BayesPrism technical input violation.

These software-specific conclusions are not yet backed by a committed requirements-review artifact. Their version-specific documentation and code references should be retained when BayesPrism is pinned and input preparation is implemented.

## 7. Planned script sequence

| Stage | Description | Current status |
| --- | --- | --- |
| 01 | TCGA-BRCA acquisition | Implemented and successfully executed |
| 02 | TCGA bulk QC/preprocessing | Specified in project discussion; script not created |
| 03 | Breast cancer scRNA-seq reference acquisition | Planned; reference not selected |
| 04 | scRNA-seq reference preprocessing | Planned; QC, annotation, and filtering pending |
| 05 | Gene identifier harmonization | Planned; identifier and duplicate handling pending |
| 06 | BayesPrism input preparation | Planned; implementation and final cleanup choices pending |
| 07 | BayesPrism deconvolution | Planned; software not installed or pinned |
| 08 | Deconvolution QC and validation | Planned |
| 09 | Downstream analyses | Planned |
| 10 | Figures and summary tables | Planned |

The stage numbering follows `docs/workflow.md`. No empty analysis scripts should be pre-created.

## 8. Script 02 design status

The methodological specification for `scripts/02_preprocess_tcga_bulk.R` has been agreed in the project discussion. The script has not yet been created or executed.

Its responsibilities are:

- Load an explicitly selected acquisition object from external processed storage.
- Use only the `unstranded` assay in gene-by-sample orientation.
- Validate object structure, metadata alignment, identifiers, and raw-count values.
- Calculate sample QC: library size, detected genes and proportion, zero-total status, identifier diagnostics, sample-type distribution, and samples per patient.
- Calculate gene QC: total counts, expression prevalence, all-zero status, gene-type distribution, annotation completeness, duplicate diagnostics, and Ensembl version-suffix diagnostics.
- Report multiple samples per patient without selecting or collapsing them.
- Preserve identifier-specific diagnostics externally and log aggregate information only.
- Record input and script checksums, versions, timestamps, and validation status.
- Perform no expression-data transformation.

Intended external artifacts:

```text
sample_qc.tsv
gene_qc.tsv
multiple_samples_per_patient.tsv
qc_summary.yml
session_info.txt
preprocess_tcga_bulk.log
```

Planned output hierarchy:

```text
intermediate/tcga_brca/<acquisition_run_id>/02_preprocess/<qc_run_id>/
```

These outputs do not yet exist as script-02 products.

Structural failures must stop execution. Expected findings such as all-zero genes, duplicate gene symbols, and multiple samples per patient must be reported without automatic exclusion. Available diagnostic evidence should be retained if a run fails.

## 9. Unresolved scientific and analytical decisions

### Cohort

The sTIL-based restriction awaits collaborator confirmation. The scoring dataset’s original provenance, publication, access conditions, and eligibility criteria remain unverified.

### Multiple Primary Tumor samples

Eleven patients have multiple Primary Tumor samples. This is not inherently a BayesPrism technical input violation, but handling remains unresolved for analyses requiring independent patient-level observations. Do not silently select, remove, or aggregate samples.

### scRNA-seq reference

The reference dataset is not selected. Reference QC, cell-type and cell-state annotation, malignant-cell representation, donor coverage, and filtering remain undecided.

### Gene harmonization

Ensembl version-suffix handling and duplicate-symbol resolution remain undecided. The final canonical identifier strategy depends on the selected reference.

### BayesPrism

BayesPrism is not installed or version-pinned. Final cleanup, filtering, and model parameters remain undecided. Protein-coding-only filtering has not been adopted as a project rule.

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
| Last recorded renv status | “No issues found -- the project is in a consistent state.” |
| BayesPrism | Not installed or version-pinned |

`renv` was initialized after acquisition; its committed lockfile records the current project dependency environment.

Normal renv sandbox activation hangs in the local Windows environment. An ignored, machine-specific `.Renviron` uses:

```text
RENV_CONFIG_SANDBOX_ENABLED=FALSE
```

This workaround is not committed and is not a cross-platform requirement. Other environments should use the default sandbox unless independently shown to require the workaround.

HPC software versions, system libraries, scheduler settings, and resource requirements remain unconfirmed. No fresh R environment test was performed for this handoff.

## 11. Data and provenance records

| Record | Authoritative role |
| --- | --- |
| `AGENTS.md` | Repository-wide scientific integrity, data protection, coding, and Git rules |
| `metadata/data_sources.tsv` | Dataset provenance, confirmed releases and retrieval dates, intended uses, and unresolved source details |
| `docs/analytical_decisions.md` | Confirmed, provisional, and pending analytical decisions and documented acquisition counts |
| `docs/workflow.md` | Implemented workflow, stage ordering, input/output categories, and data-location conventions |
| `docs/environment.md` | Confirmed execution environment and local versus HPC considerations |
| `renv.lock` | Machine-readable dependency versions and sources |
| `config/paths.example.yml` | Safe configuration schema, including the explicit acquisition-run selector |
| `scripts/01_acquire_tcga_bulk.R` | Exact implemented acquisition behavior |
| `README.md` | Scientific overview; its status and structure sections currently retain earlier planning information |

The provenance record identifies TCGA input as **GDC Data Release 46.0**, retrieved on **2026-09-15**. sTIL source details and the scRNA-seq reference remain unresolved.

External run provenance, logs, manifests, and QC reports provide execution-specific evidence and may contain identifiers. They must remain outside Git.

`PROJECT_STATUS.md` is a handoff snapshot, not a replacement for these detailed records. When records conflict, inspect the implementation and relevant execution evidence, document the discrepancy, and update the appropriate record explicitly.

## 12. Immediate next action

Create and review `scripts/02_preprocess_tcga_bulk.R` according to the agreed QC and validation specification.

Review the script and perform a syntax-only parse before executing it against the selected acquisition dataset.

## 13. Handoff rules

- Read `PROJECT_STATUS.md` first, then consult the authoritative detailed records.
- Use repository records for decisions already documented; do not reconstruct them from chat history.
- Preserve the distinction between repository-backed facts and discussion-confirmed observations awaiting a committed artifact.
- Do not commit patient-level data or large expression matrices.
- Do not modify raw data.
- Do not silently filter or exclude samples or genes.
- Distinguish planned, implemented, and successfully executed work.
- Inspect logs, expected outputs, and QC before declaring success.
- Update this handoff when the project state materially changes; Git history remains the historical record.

---

Verification note: The inspected committed files do not record the successful run ID, zero missing requested patients, zero duplicate sample identifiers, detailed expression-object inspection results, BayesPrism requirements review, or agreed script-02 specification. These were labelled as confirmed in prior project discussion rather than repository-backed findings. Local branch references are synchronized, but no fresh fetch or external-data inspection was performed.
