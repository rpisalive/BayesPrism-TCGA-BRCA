# Repository instructions

## Project scope

This is an R-based research bioinformatics project using BayesPrism
to deconvolve TCGA-BRCA bulk RNA-seq with a breast cancer single-cell
RNA-seq reference, followed by quality assessment and downstream analyses.

These instructions apply throughout the repository.

## Scientific integrity and reproducibility

- Prioritize scientific reproducibility, traceability, and biological validity.
- Never fabricate biological results, numerical outputs, citations, or interpretations.
- Clearly distinguish planned analyses, executed analyses, observed results,
  and hypotheses.
- Never assume that a script ran successfully. Inspect its logs, expected
  outputs, and relevant QC before reporting success.
- If execution or verification is incomplete, state what remains unverified.
- Record data sources, accessions, releases, retrieval dates, and checksums
  where available.
- Document package versions, important analysis parameters, filtering criteria,
  and major analytical decisions.
- Set and record random seeds for stochastic analyses when appropriate.
  Document parallel random-number handling where relevant.
- Explain major biological and statistical assumptions in comments or documentation.
- Never invent references. Verify that cited sources support the associated claims.

## Data protection and organization

- Do not modify raw data. Treat raw inputs as immutable and write transformations
  to separate processed-data locations.
- Clearly distinguish raw data, processed data, intermediate results,
  and final results.
- Do not commit large expression matrices, TCGA patient-level data, credentials,
  access tokens, or restricted data.
- Use Git for scripts, configuration, documentation, small non-sensitive metadata
  files, summary tables, and appropriate figures.
- Review metadata and derived outputs for sensitive information before committing.
  A small file is not automatically suitable for Git.
- Keep large and restricted inputs outside Git. Document how authorized users
  can obtain them without exposing private locations or credentials.
- Maintain appropriate ignore rules for local data, generated large files,
  credentials, and machine-specific settings.
- Preserve intermediate QC information. Record exclusions of samples, cells,
  and genes with their reasons and relevant counts.
- Do not silently discard failed samples or change filtering thresholds.

## Workflow and analytical history

- Prefer numbered analysis scripts that reflect execution order.
- Document each stage's inputs, outputs, dependencies, and execution instructions.
- Use relative paths or configuration files instead of hard-coded
  machine-specific paths whenever possible.
- Keep machine-specific data roots and resource settings in local configuration
  or environment variables; provide non-sensitive configuration examples.
- Before changing existing code, inspect the relevant scripts and understand
  upstream and downstream dependencies.
- Avoid unnecessary refactoring of validated analysis code.
- Do not overwrite earlier analysis scripts solely to change an analytical
  decision. Preserve meaningful history through Git, documented configurations,
  and distinct analysis variants where appropriate.
- Keep outputs from materially different analysis settings distinguishable.
  Do not silently replace results from an earlier run.
- Keep the README synchronized with major changes to data sources,
  workflow stages, execution instructions, and project status.

## BayesPrism and biological assumptions

- When uncertain about BayesPrism-specific requirements, identify the uncertainty
  and consult the documentation for the version in use rather than guessing.
- Verify expression units, matrix orientation, gene identifiers, and alignment
  of expression matrices with sample metadata and cell labels.
- Document gene harmonization, duplicate handling, reference filtering,
  malignant-cell identification, and cell-type versus cell-state annotations.
- Assess reference coverage and representativeness, including donor,
  subtype, and cell-population coverage.
- Explain limitations arising from missing populations, similar expression
  profiles, platform differences, and unmatched reference donors.
- Describe inferred fractions and expression estimates according to their
  actual model interpretation. Do not present them as direct biological
  measurements or imply causality from associations.

## R coding practices

- Write clear, focused scripts and functions with descriptive names.
- Centralize shared parameters in configuration rather than repeating
  unexplained constants across scripts.
- Declare dependencies explicitly and record a reproducible environment,
  preferably with a package lockfile and the R/Bioconductor versions.
- Do not install or update packages silently inside analysis scripts.
- Avoid reliance on an existing interactive R session, restored `.RData`,
  or undocumented global objects.
- Validate important inputs early and fail with informative messages when
  required files, columns, identifiers, or dimensions are inconsistent.
- Use explicit package namespaces where they improve clarity or avoid conflicts.
- Preserve identifiers when reading and writing data.
- Handle missing values explicitly and document their analytical treatment.
- Log important dimensions, filtering counts, parameters, warnings,
  and output locations.
- Use checks appropriate to the change, including small non-sensitive fixtures
  where useful. Do not treat successful execution alone as scientific validation.
- After changes, inspect representative outputs and relevant QC.
  Document any checks that could not be completed.

## Git practices

- Inspect the working tree and diff before staging or committing.
- Stage specific files and review staged contents for sensitive data,
  unintended outputs, and large files.
- Make focused commits with messages describing the change and its purpose.
- Preserve unrelated work and do not use destructive Git operations without
  explicit authorization.
- Do not rewrite shared history or force-push without explicit authorization.
- Record meaningful analytical changes with enough context to understand
  their rationale and effects.
- Never claim that a commit, test, or analysis was completed unless it was
  actually performed and verified.
