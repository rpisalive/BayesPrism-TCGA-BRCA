# Breast cancer scRNA-seq reference selection

**Framework recorded:** 2026-10-06

**Status:** Approved selection criteria; no candidate-reference search, candidate assessment, or reference selection has begun under this framework.

## Purpose and scope

This document prespecifies how candidate human breast cancer single-cell datasets will be screened and compared for a BayesPrism reference. Eligibility is assessed before comparing eligible datasets. No aggregate numerical score can compensate for a failed required criterion. Candidate assessments and the final rationale will be added here before production deconvolution, with changes recorded under [Change control](#change-control).

The current bulk input is the provisional sTIL-matched TCGA-BRCA Primary Tumor cohort: 60,660 genes, 869 samples, and 853 patients, with raw `unstranded` STAR counts. Stage 01 acquisition run `20260915T222828_15620` and Stage 02 QC run `20261006T151501_23332` succeeded; Stage 02 used execution commit `ff27402350973c49a4e735c8a3f18a23082e68e3`. Neither stage filtered genes or samples. The sTIL restriction awaits collaborator confirmation. Stages 03–10 remain unimplemented, BayesPrism remains uninstalled and unpinned, and no deconvolution has occurred. See [PROJECT_STATUS.md](../PROJECT_STATUS.md) for the detailed handoff.

## BayesPrism constraints, guidance, and project rules

These categories must not be conflated. The software behavior below reflects the [official BayesPrism README](https://github.com/Danko-Lab/BayesPrism/blob/main/README.md) and the currently published [`new.prism()` source](https://github.com/Danko-Lab/BayesPrism/blob/main/BayesPrism/R/new_prism.R). Recheck the exact source and documentation after the project pins a BayesPrism version.

| Category | Implication for reference selection |
| --- | --- |
| **Software-enforced constraints** | For `input.type = "count.matrix"`, the eventual reference is a cell-by-gene matrix (a dense matrix or supported sparse `dgCMatrix`) with gene identifiers as column names; labels must align with reference rows, and each cell state must map to one cell type. The eventual bulk mixture is sample-by-gene. Inputs with negative or non-finite values are rejected. `new.prism()` intersects reference and mixture gene names, stops if none match, and removes reference genes with zero total counts. These checks apply to constructed inputs, not to a candidate dataset's published file layout. |
| **BayesPrism recommendations and modelling assumptions** | Use untransformed raw counts when supplying individual cells; normalized or log-like inputs cause warnings rather than a universal hard rejection. Aim to represent all major cell populations in the mixture because omitted populations can inflate estimated fractions of included populations. The authors recommend more than 20 cells per state; the source reports small states rather than rejecting them. Represent malignant heterogeneity with appropriate states and identify malignant cells through the `key` argument for unmatched tumor references. The authors also recommend reviewing genes vulnerable to platform effects during later input preparation. |
| **Project methodological requirements** | Screen for human invasive primary breast tumor relevance, usable untransformed cell counts, defensible malignant-cell labels, adequate broad-compartment coverage, auditable cell-to-sample provenance, assessable gene identifiers, and permitted research reuse. These are prespecified quality rules, not claims that BayesPrism enforces them. |
| **Strong preferences and contextual information** | Prefer treatment-naive tumors, multiple independent donors, broad subtype representation, documented platforms and annotation methods, and rich QC and clinical context. Missing contextual metadata reduces confidence but does not automatically fail software input validation. |
| **Sensitivity or validation triggers** | Evaluate modality, treatment, normal epithelial inclusion, donor imbalance, narrow subtype coverage, matched TCGA cases, platform differences, and annotation uncertainty through explicit comparisons where feasible. Do not silently alter the reference to improve deconvolution results. |

BayesPrism accepts a collapsed gene-expression profile as another input type, but individual untransformed counts are preferred here because they permit cell-level QC, donor-balance assessment, and auditable reannotation. The software's common-gene intersection does not establish that the overlap is biologically adequate.

## Required eligibility screen for the default primary reference

A candidate must satisfy every item below, or be marked `requires_clarification` until the missing evidence is obtained. A failed item makes it `ineligible` as the **default primary reference**; it may still be documented as a separate sensitivity or supplementary source where scientifically justified.

1. **Biological context:** Human breast cancer tissue including invasive primary tumors. Metastatic-only material cannot serve as the default primary reference for the current TCGA-BRCA Primary Tumor cohort. Mixed primary and metastatic material must be distinguishable so default construction can use the primary component.
2. **Usable expression:** Cell-level untransformed counts are obtainable with documented processing and a traceable link to cell labels. Processed or log-normalized values alone do not satisfy the preferred count-matrix design. Assess whether counts are UMI-based and whether raw/unfiltered matrices are accessible; neither sequencing chemistry nor unfiltered droplets alone is a universal eligibility requirement.
3. **Compartment coverage:** Evidence supports adequate malignant epithelial, lymphoid, myeloid, fibroblast/stromal, and endothelial coverage after candidate QC. A dataset missing an entire major compartment does not qualify as the standalone default reference. Missing a rare population or finer state may be acceptable with its limitation and sensitivity handling documented. Adequacy is judged from independent donors, retained cells, annotation confidence, and biological breadth, without a fixed cell-count quota.
4. **Annotations:** Malignant epithelial cells can be distinguished defensibly from normal epithelial cells. Published malignant labels and described supporting methods suffice for screening; an independent audit of malignant assignments is required during Stage 04. Broad cell lineages must be defensible at selection, even if finer labels need later harmonization.
5. **Identifiers and provenance:** Cell-to-sample mapping, and donor identity where available under permitted access, are sufficient to assess independence and imbalance. Gene namespace and annotation source are recoverable enough to evaluate a reproducible mapping to TCGA genes. Stable source records, data-use terms, and available methods permit acquisition and authorized analysis. No patient-level identifiers enter Git.

Do not impose an arbitrary minimum number of donors, total cells, subtype proportions, gene-overlap genes, or maximum donor contribution at screening. If adequacy cannot be judged, record the uncertainty and seek clarification before declaring eligibility.

## Comparative rules for eligible candidates

### Tissue, treatment, and subtype

Treatment-naive primary tumors are **strongly preferred**, not universally mandatory. Record treatment status and timing; treated tissue may remain eligible if its contribution can be assessed and any treatment-associated expression shift is addressed by sensitivity analysis. Prefer coverage across major breast cancer molecular/subtype diversity without setting subtype quotas. A narrowly sampled subtype is a limitation for cohort-wide inference and may motivate a second reference or stratified sensitivity analysis.

Adjacent-normal breast tissue is excluded from **default primary-reference construction**. Keep it separately identified when available for diagnostic or sensitivity analysis. In particular, test whether normal epithelial profiles that resemble malignant cells affect tumor-fraction estimates; BayesPrism explicitly cautions about this type of similarity in unmatched tumor deconvolution. Normal tissue is neither mandatory nor automatically evidence of better representativeness. [BayesPrism README](https://github.com/Danko-Lab/BayesPrism/blob/main/README.md)

### Cell populations and annotation taxonomy

Assess malignant epithelial, lymphoid, myeloid, fibroblast/stromal, and endothelial lineages first. Within lymphoid cells, T, B/plasma, and NK representation is strongly preferred where biologically present. Other breast-tumor-relevant populations and finer states are assessed according to evidence; every rare subtype need not be present.

Record original labels, marker evidence, and malignant-cell identification methods. Published labels are screened for plausibility, then audited independently in Stage 04 using available evidence. Inconsistent or overly granular published labels are not by themselves exclusionary if reproducible reannotation is possible. Select a dataset using defensible broad lineages; harmonize the final BayesPrism cell-type and cell-state taxonomy later. BayesPrism recommends retaining informative cell subtypes as types and using states for finer variation; it does not require a fixed breast-cancer taxonomy. [BayesPrism README](https://github.com/Danko-Lab/BayesPrism/blob/main/README.md)

### Donor representation and reference balance

Compare independent patient count, contribution per donor and lineage, subtype distribution, and availability of sex, age, stage, treatment, and sampling-region information. Multiple regions or libraries from one patient count as one independent donor. A large cell total from a few donors does not substitute for patient diversity. Evaluate small populations and heavily imbalanced lineages using both retained cell count and donor diversity. BayesPrism's recommendation of more than 20 cells per state is guidance for later reference construction, **not** a hard dataset exclusion rule. Downsampling, donor balancing, or state merging remains a later documented decision, not a screening action. [BayesPrism README](https://github.com/Danko-Lab/BayesPrism/blob/main/README.md)

Record cell-level QC, doublet and ambient-RNA handling, sparsity, batch/library labels, chemistry, and dissociation or sample-processing methods where available. These details inform bias assessment; missing individual clinical or QC fields are not automatic exclusions when the reference can otherwise be evaluated.

### Gene space and TCGA compatibility

Before harmonization, record each candidate's gene namespace, genome build/annotation release where recoverable, Ensembl version suffixes, duplicated gene symbols or IDs, and whether counts can be mapped to unique analysis identifiers without silent aggregation. Assess expected overlap with TCGA after a documented mapping plan; do not set a fixed overlap threshold at selection.

The bulk has unique `gene_id` values, duplicated `gene_name` values, and predominantly terminal numeric Ensembl version suffixes. Those facts do not justify immediate symbol conversion or suffix stripping. Stage 05 will decide and record the identifier mapping and duplicates; Stage 06 will prepare the final common-gene input and inspect its retained gene space. Compare bulk and reference modality/platform effects rather than assuming gene-name overlap resolves expression bias. [PROJECT_STATUS.md](../PROJECT_STATUS.md), [BayesPrism README](https://github.com/Danko-Lab/BayesPrism/blob/main/README.md)

### TCGA patient and specimen matching

Where provenance and permitted metadata allow, explicitly assess whether candidate single-cell donors overlap TCGA-BRCA patients or specimens. Record one of: `none_known`, `possible_unconfirmed`, `confirmed_patient_match`, `confirmed_specimen_or_aliquot_match`, or `unknown`, together with the evidence level and how matching was assessed. Do not publish identifiers or private linkage data in this repository.

TCGA matching is **not** an eligibility requirement and does not automatically make a candidate the best cohort-wide reference. Limited genuinely matched cases are preferentially reserved for independent validation or patient-specific sensitivity analysis. Where feasible, exclude a patient's own cells from the reference used to validate deconvolution of that patient's bulk sample. A matched single-cell sample is supportive validation evidence, not absolute ground truth: sampling, modality, processing, and cell capture can differ from bulk. If extensive matched data are discovered, reassess and document the design prospectively before production analysis.

### Modality, access, and provenance

Candidate discovery should prospectively include both scRNA-seq primary-reference candidates and relevant snRNA-seq sensitivity candidates. The intended primary-reference modality remains scRNA-seq; evaluate snRNA-seq separately and do not naively pool its nuclei with scRNA-seq cells. If used later, compare modality-specific findings and document cell-population capture and expression differences. Multiple scRNA-seq platforms also require assessment before combination.

Prefer peer-reviewed or equivalently well-documented provenance, stable accession and citation, accessible raw and processed files, clear licensing/reuse terms, available code or methods, and documented preprocessing. Open access is preferred, not an absolute requirement; restricted data remain eligible only if authorized access and compliant, reproducible use are feasible. Record release/version, retrieval date, and checksums when acquired. [metadata/data_sources.tsv](../metadata/data_sources.tsv) retains dataset provenance after selection.

## Single-reference and combined-reference strategy

Search for one well-characterized primary scRNA-seq reference first. Keep independently eligible alternatives for planned sensitivity comparisons. A combined reference may improve biological coverage, but only after each source's eligibility, donor balance, platform effects, gene mapping, and broad-lineage labels are assessed separately. Prespecify the reason for combination and document harmonization and any cell balancing before constructing it. Do not combine sources merely because a larger pooled reference appears to yield preferred deconvolution results.

## Sensitivity and validation triggers

| Trigger | Required assessment before interpretation |
| --- | --- |
| Missing rare population or uncertain minor state | Document likely bias and compare a reference with better coverage where feasible; missing an entire major compartment fails default-reference eligibility. |
| Treated tissue or narrow subtype representation | Compare against treatment-naive or broader eligible material where available; qualify cohort-wide claims. |
| Adjacent-normal epithelial cells | Keep separate and compare inclusion only as a diagnostic/sensitivity analysis. |
| snRNA-seq or mixed sequencing platforms | Analyze by modality/platform before any combined construction. |
| One donor dominates a lineage; few independent donors | Assess donor-balanced or leave-one-donor-out references where feasible. |
| Uncertain malignant labels or fine taxonomy | Audit labels in Stage 04 and compare defensible broad versus refined annotations. |
| Limited confirmed TCGA matches | Reserve for independent or patient-specific validation where feasible; prevent the same patient's cells from informing that validation reference. |
| Low or biased gene overlap; bulk-high/reference-undetected genes | Inspect the mapped common-gene space and platform-sensitive genes during Stages 05–06; document any later exclusions. |

BayesPrism's own guidance recommends assessing malignant representativeness with leave-one-out tests and warns that missing cell populations and platform effects can bias inferred fractions. These tests are methodological checks, not proof that a reference captures every population. [BayesPrism README](https://github.com/Danko-Lab/BayesPrism/blob/main/README.md)

## Candidate evaluation schema

Maintain one row per candidate with stable `candidate_id`; keep patient-level linkage and expression data outside Git. Use two linked sections rather than an aggregate score.

**Eligibility screen:** `candidate_id`, `citation_or_title`, `accession_or_repository`, `human_breast_cancer`, `invasive_primary_tumor_available`, `metastatic_only`, `modality`, `treatment_context`, `usable_untransformed_cell_counts`, `cell_annotation_linkable`, `malignant_annotation_evaluable`, `major_compartment_coverage`, `sample_or_donor_mapping_adequate`, `gene_namespace_evaluable`, `TCGA_match_status`, `reuse_permitted`, `provenance_adequate`, `eligibility_decision`, `exclusion_or_clarification_reason`.

Use `eligible`, `ineligible`, or `requires_clarification` for `eligibility_decision`. Document evidence for each required field. Record `modality`, `treatment_context`, and `TCGA_match_status` during screening; treatment status and TCGA matching are contextual, not automatic eligibility failures. A required failure cannot be offset by strengths in another field.

**Qualitative comparison of eligible candidates:** `candidate_id`, `tissue_and_primary_metastatic_context`, `treatment_context`, `scRNA_or_snRNA`, `platform_and_chemistry`, `independent_donors`, `total_cells`, `donor_and_lineage_balance`, `subtype_coverage`, `malignant_evidence`, `lymphoid_myeloid_stromal_endothelial_coverage`, `other_populations`, `raw_count_and_cell_QC_availability`, `original_labels_and_marker_evidence`, `gene_namespace_build_and_annotation`, `duplicate_and_version_suffix_assessment`, `expected_TCGA_gene_overlap`, `TCGA_match_status`, `TCGA_match_evidence_level`, `access_and_reuse_terms`, `published_methods_or_code`, `strengths`, `limitations`, `sensitivity_or_validation_plan`, `final_selection_justification`.

Counts and proportions in this comparison are descriptive, not quota-based scores. Use `unknown` when evidence is unavailable; do not infer missing clinical or matching details. Candidate-level assessment can be committed only after checking for sensitive metadata.

## Final selection rule

Select the default primary reference only from candidates that pass the eligibility screen. Compare them qualitatively on primary-tumor relevance, malignant and major-compartment evidence, independent-donor breadth, subtype coverage, usable counts and annotations, gene-space compatibility, provenance, and foreseeable biases. Record why the chosen dataset is preferable for the prespecified TCGA-BRCA analysis, why alternatives were not chosen, what limitations remain, and which independent validation or sensitivity analyses are planned. Make this decision before inspecting production deconvolution outcomes. Record any later departure from the rule and its effect on interpretation.

The final Methods account should be able to identify the dataset accession and version, donor and tissue context, count source, annotation and malignant-cell evidence, broad-lineage coverage, gene mapping, quality decisions, access terms, and the rationale for the reference and sensitivity choices without exposing private identifiers.

## Change control

This framework was approved before candidate searching. Add candidate assessments and the final selection rationale without retroactively changing the screening rules. For a material change, record the date, original rule, revised rule, scientific reason, affected candidates, and whether any deconvolution results had already been examined. Reassess all relevant candidates consistently. Keep dataset acquisition, QC, filtering, and analysis execution in their appropriate stage records; this criteria document does not authorize Stage 03 code or a production BayesPrism run.
