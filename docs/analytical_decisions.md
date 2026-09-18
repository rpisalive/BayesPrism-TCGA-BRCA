# Analytical decisions

**Decision record date:** 2026-09-19  
**Purpose:** Record confirmed, provisional, and pending analytical decisions for the BayesPrism TCGA-BRCA workflow. This document records the current state of the project and will be updated as decisions are confirmed.

## TCGA-BRCA bulk RNA-seq acquisition

**Confirmed decision**

The successful acquisition run on 2026-09-15 used NCI Genomic Data Commons TCGA-BRCA data with:

- Data category: Transcriptome Profiling
- Data type: Gene Expression Quantification
- Workflow: STAR - Counts
- Experimental strategy: RNA-Seq
- Access level: open
- Final downloaded sample type: Primary Tumor
- Retained assay: `unstranded`
- Expression values: raw counts

No normalization, transformation, or gene filtering was applied during acquisition. The immutable GDC source files remain external to the repository; exported raw-count matrices are derived files stored externally.

**Provisional decision**

None recorded for the acquisition parameters above.

**Pending decision**

Any preprocessing required for BayesPrism input preparation will be recorded separately before implementation.

## sTIL-based cohort restriction

**Confirmed decision**

The current acquisition script intersects TCGA patient IDs from the discovery query with IDs in `TCGA-sTIL_scoring.csv`. The resulting sTIL-matched patient set defines the currently downloaded TCGA-BRCA cohort.

**Provisional decision**

The sTIL-based cohort restriction is provisional. It must be confirmed with the collaborator before it is treated as the final study-cohort definition.

**Pending decision**

- Confirm the original provenance, publication, accession or source location, version, and eligibility criteria for `TCGA-sTIL_scoring.csv`.
- Confirm whether the sTIL-based restriction should define the final study cohort.

## Current successful acquisition run

**Confirmed decision**

The following counts describe the successful acquisition run on 2026-09-15:

| Quantity | Count |
|---|---:|
| TCGA patients in RNA-seq discovery query | 1,095 |
| Unique sTIL IDs | 854 |
| Overlapping and requested patients | 853 |
| Recovered patients | 853 |
| Recovered Primary Tumor samples | 869 |
| Genes | 60,660 |

These values describe the current successful acquisition run. They do not necessarily define the final publication cohort.

**Provisional decision**

The current counts reflect the provisional sTIL-matched cohort restriction.

**Pending decision**

Confirm the final study-cohort definition before analyses intended to support publication conclusions.

## Multiple Primary Tumor samples per patient

**Confirmed decision**

Eleven patients in the current acquisition run have more than one recovered Primary Tumor sample. No samples were removed, selected, or collapsed during acquisition. Identifier-specific diagnostic reports are retained externally.

**Provisional decision**

None recorded.

**Pending decision**

Define and document the rule for selecting or handling one sample per patient before analyses that require independent patient-level observations.

## Breast cancer single-cell RNA-seq reference

**Confirmed decision**

No breast cancer scRNA-seq reference dataset has yet been selected or confirmed.

**Provisional decision**

None recorded.

**Pending decision**

- Select and document the reference dataset and its provenance.
- Define the cell-type annotation strategy.
- Assess malignant-cell representation.
- Define reference quality-control and filtering decisions.

## BayesPrism

**Confirmed decision**

BayesPrism has not yet been installed or version-pinned for this project. No BayesPrism analysis has been run.

**Provisional decision**

None recorded.

**Pending decision**

- Record the BayesPrism installation source and version or commit.
- Define and document BayesPrism input requirements, parameters, and filtering decisions.
- Confirm gene-identifier harmonization, duplicate handling, reference composition, and relevant quality-assessment criteria before deconvolution.
