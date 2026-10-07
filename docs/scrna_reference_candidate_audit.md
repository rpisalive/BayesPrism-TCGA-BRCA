# Breast cancer scRNA-seq reference candidate audit

**Audit record date:** 2026-10-08

**Status:** Discovery, deduplication, eligibility screening, and source-level confirmation substantially complete at study level; primary reference unselected.

This handoff records the project screening findings supplied for this documentation update. It does not replace accession-specific source records, exact sample manifests, or later Stage-04 QC. Remaining ambiguities are identified below; no candidate dataset was acquired or analyzed as part of this update.

The study-level list below concerns scRNA-seq primary-reference candidates. The frozen framework also permits relevant snRNA-seq candidates as a separate sensitivity modality; none is selected by this audit.

## Authority and boundaries

[scrna_reference_selection.md](scrna_reference_selection.md) is the authoritative pre-search framework, frozen at commit `1d158dae3479fddb80e9d024a3cb57ef24845b1b`. Eligibility was screened before comparative selection; no aggregate numerical score was used. No production BayesPrism deconvolution result was inspected during screening. The default design is one primary scRNA-seq reference if a single study is adequate, with limited sensitivity references where useful. A pooled multi-study reference is not the default. Eligibility permits qualitative comparison; it does not mean every eligible dataset will be acquired or used.

## Scientific endpoint clarification

The principal downstream biological question is the relationship between BayesPrism-inferred immune-cell populations in TCGA-BRCA tumours and patient-level sTIL scores in `TCGA-sTIL_scoring.csv`. This objective was clarified after candidate eligibility screening had substantially progressed, but before primary-reference selection, Stage-03 implementation, or examination of any production BayesPrism result.

The frozen eligibility criteria are unchanged. This clarification changes the emphasis of qualitative comparison among eligible candidates. An earlier provisional preference for Pal as primary, Wu as a sensitivity reference, and Bassez baseline as a second sensitivity reference is reopened. No primary reference has been selected. The sTIL-based restriction of the currently acquired bulk cohort separately remains provisional pending collaborator confirmation.

## Discovery and deduplication

Treat study-level candidates, donors, libraries, and derivative releases distinctly. Do not count the following records as independent evidence:

| Records | Deduplication rule |
| --- | --- |
| `GSE248288` and `GSE255107` | One study-level candidate; overlapping donors/libraries must not be counted twice. |
| `GSE190811` / `GSE190870` and `GSE167036` | The former are associated spatial/SuperSeries records, not independent scRNA-seq references. |
| `GSE276609` and `GSE161529` | The former is derivative/downstream Pal material, not an independent cohort. |
| Earlier Wu TNBC repository records | Do not count as independent without a patient crosswalk. |
| Integrated breast-cancer atlas/CELLxGENE resources | Derivative discovery integrations, not independent cohorts. |

## Eligible candidates at study-level screening

The 13 candidates below pass screening **for the stated eligible subset**. Exact sample inclusion, donor/library deduplication, accession-specific provenance, and later QC still require confirmation before construction of any reference.

| Candidate | Study-level record | Eligible subset and material limitation |
| --- | --- | --- |
| 1. Pal et al. 2021 | `GSE161529` | Treatment-naive invasive primary tumours only; exclude normal, preneoplastic, and lymph-node material. Exact sample/patient manifest still needs freezing. |
| 2. Wu et al. 2021 | `GSE176078` | Untreated primary tumours; exclude five treatment-exposed cases. |
| 3. Bassez et al. 2021 / BioKey | `EGAS00001004809`, `EGAD00001006608`, plus public author count release | Cohort-1 baseline/pre-pembrolizumab biopsies only; exclude on-treatment samples and chemotherapy-exposed Cohort 2. |
| 4. Qian et al. 2020 | `E-MTAB-8107` | Treatment-naive breast-cancer subset. |
| 5. Regner et al. 2025 | `GSE243526` | Primary treatment-naive cohort. |
| 6. Liu et al. 2022 | `GSE167036` | Primary tumours only; exclude paired metastatic lymph nodes. |
| 7. Xu et al. 2021 | `GSE180286` | Primary tumours only; exclude paired lymph nodes. |
| 8. Liu et al. 2023 | `GSE225600` | Primary tumours only; exclude paired metastatic lymph nodes. |
| 9. Gao / CopyKAT | `GSE148673` | Invasive TNBC subset; subtype restricted. |
| 10. Untreated HR+/HER2− study | `GSE228499` | Untreated HR+/HER2− primary tumours; subtype restricted. |
| 11. Control-aliquot study | `GSE245601` | Control aliquots only; ER+/HER2− restriction and 12-hour ex-vivo handling are important limitations. |
| 12. Wang/Tan/Guo | `GSE248288` + `GSE255107` | One deduplicated study-level candidate; accession overlap and duplicate donors require explicit handling. |
| 13. Ozmen et al. 2025 | `GSE306201` | Primary tumours only; ER+-restricted. Keep the publication-versus-current-BioProject accession discrepancy documented. |

## Requires clarification or deprioritized

Do not spend further effort on these unless stronger eligible candidates prove inadequate.

| Candidate | Reason |
| --- | --- |
| Tietscher / `E-MTAB-10607` | Malignant-versus-normal epithelial distinction is insufficiently explicit. |
| `GSE205472` | Biologically plausible pre-NAC reference, but reuse/data-use terms remain unresolved. |
| `GSE195861` | Complete five-compartment coverage within an invasive-primary-only subset is not firmly established. |
| `OMIX006159` | Malignant epithelial distinction and controlled-access/reuse remain unresolved. |
| `GSE264205` | Single de-novo stage-IV patient; technically unresolved and deprioritized for cohort-wide default use. |

## Ineligible as standalone default references

| Candidate | Reason |
| --- | --- |
| `GSE75688` | Insufficient whole-TME fibroblast/endothelial coverage. |
| `GSE114727` | CD45+ immune-focused sampling; malignant/stromal compartments absent or underrepresented. |
| `GSE155109` | Endothelial/stromal-enriched; inadequate malignant epithelial standalone reference. |
| `GSE188807` | Metastatic-only tissue. |
| `GSE328275` | CD45+ immune-sorted TNBC; malignant/stromal/endothelial compartments intentionally absent. |

An immune-rich dataset can still be unsuitable as a standalone BayesPrism reference when major non-immune compartments are omitted. These findings concern default-reference eligibility, not every possible use in a separately justified sensitivity analysis.

## TCGA-BRCA overlap

Screening identified no **confirmed** TCGA-BRCA donor, specimen, or aliquot match. The working status for most inspectable candidates is `none_known`, which does not prove overlap impossible. `OMIX006159` remains effectively `unknown`. Perform a final accession-specific overlap audit for the selected candidate, without putting patient-level linkage in Git. The frozen framework does not require TCGA matching for eligibility and treats genuine matches as potential validation evidence, not ground truth.

## Preliminary comparison before endpoint clarification

An earlier general whole-tumour comparison tentatively favoured Pal / `GSE161529` as a possible primary reference, Wu / `GSE176078` as a possible sensitivity reference, and Bassez baseline as a possible second sensitivity reference. This was provisional, was not frozen, and is now reopened for the immune/sTIL endpoint. None has been selected.

## Immune-focused next comparison

Compare serious eligible scRNA-seq candidates using the **exact eligible sample subset**, with attention to:

- immune-cell depth and independent donor support for T, B/plasma, NK, and myeloid populations;
- rare immune-population representation across donors;
- annotation reliability, marker support, and whether labels suit BayesPrism cell types versus states without excessive sparse-state fragmentation;
- treatment, sorting/enrichment, biopsy, dissociation, chemistry, and ex-vivo effects;
- malignant, fibroblast/stromal, and endothelial completeness to avoid omitted-population bias; and
- suitability for comparing inferred immune fractions with patient-level sTIL scores.

Use qualitative evidence and explicit limitations, not an aggregate numerical score. Select one primary reference only after this comparison; retain sensitivity references only where they address a defined uncertainty.
