# Computational environment

## Scope

This document records the confirmed environment used for the successful
TCGA-BRCA acquisition run on 2026-09-15. It will be updated as the
single-cell reference, BayesPrism deconvolution, and downstream analyses
are implemented.

## Current R environment

- Operating system: Windows, x86_64
- R: 4.4.3 (2025-02-28 ucrt)
- Bioconductor release: 3.19

The acquisition workflow is designed to run non-interactively with
`Rscript`. It reads machine-specific data locations from an ignored local
configuration file and stores large inputs and derived objects outside Git.

## Confirmed package versions

The following package versions were recorded during the successful
TCGA-BRCA acquisition run:

| Package | Version | Current use |
|---|---:|---|
| TCGAbiolinks | 2.32.0 | GDC query, download, and preparation |
| SummarizedExperiment | 1.34.0 | TCGA expression and metadata container |
| yaml | 2.3.12 | Local path configuration |

Additional package versions should be recorded in each run's provenance
artifact and session information.

## Dependency management

`renv` is planned but has not yet been initialized. Before extending the
workflow, initialize a project-local `renv` environment, record the
resulting lockfile in Git, and document the R and Bioconductor versions
used to restore it.

Do not install or update packages silently within analysis scripts.

## BayesPrism status

BayesPrism has not yet been installed, configured, or version-pinned for
this project. Its installation source, package version or commit, required
dependencies, and runtime parameters must be recorded before the first
deconvolution analysis.

## Local and HPC execution

The confirmed acquisition run used the Windows environment described above.
Future analyses may run on HPC infrastructure. The HPC operating system,
R version, Bioconductor version, package versions, scheduler settings, and
resource requests have not yet been confirmed.

HPC runs should restore the documented project environment, use
configuration rather than machine-specific paths in scripts, and record
the execution environment with each run.

## Reproducibility expectations

- Use numbered scripts and explicit configuration.
- Keep raw data immutable and outside Git.
- Record data provenance, package versions, parameters, random seeds, and
  input-output relationships.
- Preserve QC reports and exclusion records.
- Inspect logs and outputs before reporting a run as successful.
- Record any environment differences between local and HPC execution.
