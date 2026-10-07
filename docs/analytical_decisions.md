# Analytical decisions

**Decision record date:** 2026-09-19  
**Candidate-screening update recorded:** 2026-10-08

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

The scoring CSV also supplies the patient-level sTIL scores for the principal planned downstream question: how BayesPrism-inferred immune-cell populations in TCGA-BRCA tumours relate to those scores. This scientific role does not resolve whether sTIL matching should define the final study cohort.

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

The pre-search eligibility framework in [scrna_reference_selection.md](scrna_reference_selection.md) is frozen at commit `1d158dae3479fddb80e9d024a3cb57ef24845b1b` and remains unchanged. Discovery, deduplication, eligibility screening, and source-level confirmation are substantially complete; 13 study-level candidates currently pass screening for specified eligible subsets. Their status and limitations are recorded in [scrna_reference_candidate_audit.md](scrna_reference_candidate_audit.md). Eligibility is not reference selection.

The immune-cell versus sTIL endpoint was clarified after screening substantially progressed, but before reference selection, Stage 03, or examination of production BayesPrism results. One well-characterized primary scRNA-seq reference remains the default design, with limited sensitivity references if useful. A pooled multi-study reference is not the default. The endpoint clarification changes the emphasis of qualitative comparison, not the frozen eligibility rules.

**Provisional decision**

An earlier general whole-tumour comparison tentatively favoured Pal / `GSE161529` as possible primary, Wu / `GSE176078` as possible sensitivity reference, and Bassez baseline as a possible second sensitivity reference. This preference is reopened for the immune/sTIL endpoint; none has been selected.

**Pending decision**

- Re-evaluate serious eligible candidates in their exact eligible subsets for immune depth, independent donor support for T, B/plasma, NK, and myeloid populations, rare immune populations across donors, annotation and marker reliability, and BayesPrism cell-type/state suitability.
- Assess treatment, sorting, biopsy, dissociation, chemistry, and ex-vivo effects while retaining adequate malignant, fibroblast/stromal, and endothelial coverage.
- Select and document one primary reference and any justified sensitivity reference(s), including provenance and exact sample subsets.
- Define Stage-04 reference QC, malignant-cell audit, annotation, filtering, cell-type/state taxonomy, and any donor-balancing decisions before implementation.

## BayesPrism

**Confirmed decision**

BayesPrism has not yet been installed or version-pinned for this project. No BayesPrism analysis has been run.

**Provisional decision**

None recorded.

**Pending decision**

- Record the BayesPrism installation source and version or commit.
- Define and document BayesPrism input requirements, parameters, and filtering decisions.
- Confirm gene-identifier harmonization, duplicate handling, reference composition, and relevant quality-assessment criteria before deconvolution.
