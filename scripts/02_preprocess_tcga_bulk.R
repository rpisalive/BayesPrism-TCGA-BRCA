#!/usr/bin/env Rscript

# Deterministic QC only: preserve every raw unstranded count, gene and sample.
# Run from the project environment: Rscript scripts/02_preprocess_tcga_bulk.R
# Input: the explicit acquisition run in config/local/paths.yml.
# Outputs: small external QC/provenance files, never expression objects.
# This script does not edit metadata/run_registry.tsv. Inspect the execution
# outcome before registering any succeeded, failed, interrupted or incomplete run.

qc_stop <- function(text) {
  stop(structure(list(message = text, call = NULL),
                 class = c("qc_safe_error", "error", "condition")))
}

safe_error_text <- function(error) {
  if (inherits(error, "qc_safe_error")) conditionMessage(error) else
    "Unexpected execution error; underlying text suppressed to protect identifiers."
}

# Required writes must never continue after a conversion, flush or rename warning.
# These labels are constructed by this script, never from annotation values.
qc_required_output <- function(action, label) {
  withCallingHandlers(suppressMessages(action()), warning = function(warning) {
    qc_stop(paste("Required output operation warned:", label,
                  "Underlying warning text suppressed."))
  })
}

qc_missing <- function(value) {
  # Unicode separators plus horizontal/vertical ASCII whitespace and Unicode NEL.
  # Only a diagnostic copy is converted to UTF-8; original strings are preserved.
  empty <- withCallingHandlers(
    grepl("^[\\p{Z}\\x{0009}-\\x{000D}\\x{0085}]*$", enc2utf8(value), perl = TRUE),
    warning = function(warning) qc_stop("Could not validate annotation string encoding."))
  is.na(value) | empty
}

qc_check_tsv_sentinel <- function(data, sentinel) {
  for (column in data) {
    if (is.character(column) || is.factor(column)) {
      if (any(as.character(column) == sentinel, na.rm = TRUE))
        qc_stop("Literal character value collides with the TSV missing-value sentinel.")
    }
  }
  invisible(TRUE)
}

qc_gene_type_counts <- function(value) {
  # Serialization allowlist only, not gene selection or a biological filter.
  # Unknown annotations remain unchanged in gene_qc.tsv and are bucketed here.
  known <- c(
    "protein_coding", "lncRNA", "lincRNA", "antisense", "processed_transcript",
    "sense_intronic", "sense_overlapping", "3prime_overlapping_ncRNA", "bidirectional_promoter_lncRNA",
    "miRNA", "misc_RNA", "rRNA", "rRNA_pseudogene", "Mt_rRNA", "Mt_tRNA",
    "snRNA", "snoRNA", "scaRNA", "sRNA", "scRNA", "vault_RNA", "ribozyme",
    "pseudogene", "processed_pseudogene", "unprocessed_pseudogene", "unitary_pseudogene",
    "transcribed_processed_pseudogene", "transcribed_unprocessed_pseudogene",
    "transcribed_unitary_pseudogene", "translated_processed_pseudogene",
    "translated_unprocessed_pseudogene", "polymorphic_pseudogene", "TEC",
    "IG_C_gene", "IG_D_gene", "IG_J_gene", "IG_V_gene", "IG_C_pseudogene",
    "IG_J_pseudogene", "IG_V_pseudogene", "TR_C_gene", "TR_D_gene", "TR_J_gene",
    "TR_V_gene", "TR_J_pseudogene", "TR_V_pseudogene")
  labels <- rep("OTHER_OR_UNRECOGNIZED", length(value))
  recognized <- !qc_missing(value) & value %in% known
  labels[recognized] <- value[recognized]
  labels[qc_missing(value)] <- "MISSING"
  # Fixed level order makes summary ordering independent of locale collation.
  type_counts <- table(factor(labels, levels = c(known, "MISSING", "OTHER_OR_UNRECOGNIZED")))
  as.list(type_counts[type_counts > 0L])
}

qc_finalize <- function(summary, outcome, log_value, close_log, write_summary, utc_now) {
  mark_failed <- function(error) {
    summary$qc_status <<- "failed"
    summary$failure_reason <<- safe_error_text(error)
    outcome <<- FALSE
  }
  # The log deliberately records readiness, never a premature success claim.
  tryCatch({
    log_value("Validation outcome", if (outcome) "passed" else summary$qc_status)
    log_value("Finalization", "Closing log; qc_summary.yml is the completion marker.")
  }, error = mark_failed, interrupt = function(interrupt) {
    mark_failed(structure(list(message = "Finalization interrupted.", call = NULL),
                          class = c("qc_safe_error", "error", "condition")))
  })
  log_closed <- tryCatch({
    qc_required_output(close_log, "log flush/close")
    TRUE
  }, error = function(error) { mark_failed(error); FALSE },
  interrupt = function(interrupt) {
    mark_failed(structure(list(message = "Log finalization interrupted.", call = NULL),
                          class = c("qc_safe_error", "error", "condition")))
    FALSE
  })
  if (log_closed) summary$completed_output_filenames <- c(
    summary$completed_output_filenames, "preprocess_tcga_bulk.log")
  summary$completion_time_utc <- utc_now()
  if (outcome && log_closed) summary$qc_status <- "succeeded"
  # Include the summary itself only in the candidate that will be atomically saved.
  candidate <- summary
  candidate$completed_output_filenames <- c(candidate$completed_output_filenames, "qc_summary.yml")
  summary_ok <- tryCatch({
    qc_required_output(function() write_summary(candidate), "qc_summary.yml")
    TRUE
  }, error = function(error) { mark_failed(error); FALSE },
  interrupt = function(interrupt) {
    mark_failed(structure(list(message = "Summary finalization interrupted.", call = NULL),
                          class = c("qc_safe_error", "error", "condition")))
    FALSE
  })
  if (!summary_ok) {
    # The failed success candidate never becomes the final marker. Best effort:
    # write a failure marker instead, without reopening the finalized log.
    candidate <- summary
    candidate$completed_output_filenames <- c(candidate$completed_output_filenames, "qc_summary.yml")
    tryCatch(qc_required_output(function() write_summary(candidate), "failed qc_summary.yml"),
             error = function(error) NULL, interrupt = function(interrupt) NULL)
  }
  # After a successful summary rename, only this return remains: no required I/O.
  if (outcome && log_closed && summary_ok) 0L else 1L
}

main <- function() {
  started <- Sys.time()
  utc <- function(time) format(time, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
  packages <- c("SummarizedExperiment", "yaml")
  for (pkg in packages) {
    if (!suppressMessages(requireNamespace(pkg, quietly = TRUE)))
      qc_stop(paste("Required package is unavailable:", pkg))
  }

  script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(script_arg) != 1L)
    qc_stop("Run this script with Rscript so its path and checksum are explicit.")
  script_path <- normalizePath(sub("^--file=", "", script_arg),
                               winslash = "/", mustWork = TRUE)
  project_root <- normalizePath(file.path(dirname(script_path), ".."),
                                winslash = "/", mustWork = TRUE)

  # Capture only the HEAD hash and a clean/dirty indicator, never Git filenames.
  git_value <- function(args) {
    tryCatch({
      result <- suppressWarnings(system2("git", c("-C", shQuote(project_root), args),
                                         stdout = TRUE, stderr = FALSE))
      status <- attr(result, "status")
      if (!is.null(status) && status != 0L) NULL else result
    }, error = function(error) NULL)
  }
  head <- git_value(c("rev-parse", "HEAD"))
  git_commit <- if (length(head) == 1L && grepl("^[a-fA-F0-9]{40}$", head))
    head else "unavailable"
  git_status <- git_value(c("status", "--porcelain", "--untracked-files=normal"))
  git_tree <- if (is.null(git_status)) "unavailable" else
    if (length(git_status)) "dirty" else "clean"

  config_file <- file.path(project_root, "config", "local", "paths.yml")
  if (!file.exists(config_file)) qc_stop("Missing config/local/paths.yml.")
  config <- tryCatch(suppressMessages(yaml::read_yaml(config_file, eval.expr = FALSE)),
                     error = function(error) qc_stop("Could not read local YAML configuration."))
  keys <- c("processed_data_dir", "intermediate_data_dir", "tcga_acquisition_run_id")
  for (key in keys) {
    value <- config[[key]]
    if (!is.character(value) || length(value) != 1L || is.na(value) ||
        !nzchar(trimws(value)) || grepl("/path/to/|<[^>]+>", value))
      qc_stop(paste("Missing, invalid or placeholder configuration key:", key))
  }
  acquisition_run_id <- config$tcga_acquisition_run_id
  # Match script 01's UTC timestamp/PID convention and prohibit path traversal.
  if (!grepl("^[0-9]{8}T[0-9]{6}_[0-9]+$", acquisition_run_id))
    qc_stop("Invalid explicit TCGA acquisition run ID.")
  run_time <- strptime(substr(acquisition_run_id, 1L, 15L), "%Y%m%dT%H%M%S", tz = "UTC")
  if (is.na(run_time) || !identical(format(run_time, "%Y%m%dT%H%M%S", tz = "UTC"),
                                  substr(acquisition_run_id, 1L, 15L)))
    qc_stop("Acquisition run ID contains an invalid UTC timestamp.")

  within <- function(path, parent) {
    if (.Platform$OS.type == "windows") {
      path <- tolower(path)
      parent <- tolower(parent)
    }
    parent <- sub("/+$", "", parent)
    identical(path, parent) || startsWith(path, paste0(parent, "/"))
  }
  resolve <- function(path) {
    absolute <- grepl("^(/|[A-Za-z]:[/\\\\]|\\\\\\\\)", path)
    normalizePath(if (absolute) path else file.path(project_root, path),
                  winslash = "/", mustWork = TRUE)
  }
  paths <- lapply(config[c("processed_data_dir", "intermediate_data_dir")], resolve)
  for (path in paths) {
    if (!dir.exists(path) || within(path, project_root) || within(project_root, path))
      qc_stop("Processed and intermediate roots must be directories separate from the repository.")
  }
  input_file <- file.path(paths$processed_data_dir, "tcga_brca", acquisition_run_id,
                         "TCGA_BRCA_sTIL_primary_tumor_SE.rds")
  if (!file.exists(input_file) || dir.exists(input_file))
    qc_stop("Selected acquisition RDS is missing or is not a file.")
  input_file <- normalizePath(input_file, winslash = "/", mustWork = TRUE)
  if (!within(input_file, paths$processed_data_dir) || within(input_file, project_root))
    qc_stop("Selected acquisition RDS resolves outside the external processed root.")
  input_size <- file.info(input_file)$size
  if (is.na(input_size) || input_size <= 0)
    qc_stop("Selected acquisition RDS is empty or inaccessible.")

  qc_run_id <- paste0(format(Sys.time(), "%Y%m%dT%H%M%S", tz = "UTC"), "_", Sys.getpid())
  parent_dir <- file.path(paths$intermediate_data_dir, "tcga_brca", acquisition_run_id,
                          "02_preprocess")
  # Validate existing ancestors before recursive creation, including redirected
  # directories, so a junction/symlink cannot put QC files inside the repository.
  ancestor <- parent_dir
  while (!file.exists(ancestor) && !dir.exists(ancestor)) ancestor <- dirname(ancestor)
  ancestor <- normalizePath(ancestor, winslash = "/", mustWork = TRUE)
  if (!dir.exists(ancestor) || !within(ancestor, paths$intermediate_data_dir) ||
      within(ancestor, project_root))
    qc_stop("QC output ancestor is not beneath the external intermediate root.")
  if (!dir.exists(parent_dir) &&
      !dir.create(parent_dir, recursive = TRUE, showWarnings = FALSE))
    qc_stop("Could not create the external QC parent directory.")
  parent_dir <- normalizePath(parent_dir, winslash = "/", mustWork = TRUE)
  if (!within(parent_dir, paths$intermediate_data_dir) || within(parent_dir, project_root))
    qc_stop("QC parent directory resolves outside the external intermediate root.")
  output_dir <- file.path(parent_dir, qc_run_id)
  if (file.exists(output_dir) || dir.exists(output_dir))
    qc_stop("QC run directory already exists; refusing to overwrite.")
  if (!dir.create(output_dir, showWarnings = FALSE))
    qc_stop("Could not create the new external QC run directory.")

  filenames <- c("sample_qc.tsv", "gene_qc.tsv", "multiple_samples_per_patient.tsv",
                 "qc_summary.yml", "session_info.txt", "preprocess_tcga_bulk.log")
  log_file <- qc_required_output(function()
    file(file.path(output_dir, "preprocess_tcga_bulk.log"), "wt"), "open execution log")
  log_open <- TRUE
  close_log <- function() {
    if (log_open) {
      flush(log_file)
      close(log_file)
      log_open <<- FALSE
    }
  }
  on.exit({
    if (log_open) tryCatch(qc_required_output(close_log, "defensive log cleanup"),
                          error = function(error) NULL)
  }, add = TRUE)
  log_value <- function(label, value) {
    line <- paste0(label, ": ", paste(value, collapse = ", "))
    qc_required_output(function() {
      writeLines(line, log_file)
      flush(log_file)
    }, "execution log")
    message(structure(list(message = paste0(line, "\n"), call = NULL),
                      class = c("qc_safe_message", "message", "condition")))
  }
  # Rename only complete writes; partial files retain a .tmp suffix on failure.
  atomic_write <- function(filename, writer) {
    qc_required_output(function() {
      target <- file.path(output_dir, filename)
      temporary <- paste0(target, ".tmp")
      if (file.exists(target)) qc_stop(paste("Refusing to replace completed output:", filename))
      writer(temporary)
      size <- file.info(temporary)$size
      if (is.na(size) || size <= 0 || !file.rename(temporary, target))
        qc_stop(paste("Could not complete output:", filename))
    }, filename)
  }
  # Readers must use na.strings = "<QC_MISSING>" and character ID columns;
  # literal "NA" remains a character value. Sentinel collisions are fatal.
  tsv_missing <- "<QC_MISSING>"
  write_tsv <- function(data, filename) {
    qc_check_tsv_sentinel(data, tsv_missing)
    atomic_write(filename, function(path) utils::write.table(
      data, path, sep = "\t", row.names = FALSE, col.names = TRUE,
      quote = TRUE, qmethod = "double", na = tsv_missing, fileEncoding = "UTF-8"))
  }
  checksum <- function(path) {
    value <- unname(tools::md5sum(path))
    if (length(value) != 1L || is.na(value)) qc_stop("Could not calculate an MD5 checksum.")
    value
  }
  summary <- list(
    qc_status = "failed", start_time_utc = utc(started), completion_time_utc = NULL,
    acquisition_run_id = acquisition_run_id, qc_run_id = qc_run_id,
    assay = "unstranded", input_rds_path = input_file, input_rds_size_bytes = input_size,
    checksum_algorithm = "MD5", script_path = "scripts/02_preprocess_tcga_bulk.R",
    git_commit_at_start = git_commit, git_working_tree_at_start = git_tree,
    r_version = R.version.string,
    package_versions = as.list(vapply(packages, function(pkg)
      as.character(utils::packageVersion(pkg)), character(1))),
    tsv_convention = list(encoding = "UTF-8", missing_value_sentinel = tsv_missing,
      reader_na_strings = tsv_missing, identifier_column_class = "character",
      literal_NA_is_missing = FALSE, quote_method = "double"),
    output_filenames = filenames, completed_output_filenames = character(),
    warnings = character(), fatal_conditions = character()
  )
  warning_count <- 0L
  # Only locally constructed aggregate messages are logged verbatim. Package
  # warnings/errors may embed metadata values, so their original text is suppressed.
  outcome <- tryCatch(withCallingHandlers({
    log_value("QC run ID", qc_run_id)
    log_value("Acquisition run ID", acquisition_run_id)
    log_value("Start time UTC", summary$start_time_utc)
    log_value("Git commit at start", git_commit)
    log_value("Git working tree at start", git_tree)
    summary$input_rds_md5 <- checksum(input_file)
    summary$script_md5 <- checksum(script_path)
    log_value("Input RDS MD5", summary$input_rds_md5)
    log_value("Script MD5", summary$script_md5)
    log_value("R version", summary$r_version)
    for (pkg in packages) log_value(paste(pkg, "version"), summary$package_versions[[pkg]])
    se <- tryCatch(suppressMessages(readRDS(input_file)),
                   error = function(error) qc_stop("Selected acquisition RDS is unreadable."))
    if (!methods::is(se, "RangedSummarizedExperiment"))
      qc_stop("Input is not compatible with RangedSummarizedExperiment.")
    summary$object_class <- "RangedSummarizedExperiment"
    if (!"unstranded" %in% suppressMessages(SummarizedExperiment::assayNames(se)))
      qc_stop("Required unstranded assay is missing.")
    counts <- suppressMessages(SummarizedExperiment::assay(se, "unstranded", withDimnames = FALSE))
    if (length(dim(counts)) != 2L || !nrow(counts) || !ncol(counts))
      qc_stop("Raw-count assay has zero genes or samples, or is not two-dimensional.")
    n_genes <- nrow(counts)
    n_samples <- ncol(counts)
    summary$matrix_dimensions <- list(genes = n_genes, samples = n_samples)
    summary$number_of_samples <- n_samples
    log_value("Genes", n_genes)
    log_value("Samples", n_samples)
    # Dimensions are observed, never compared against hard-coded historical counts.
    rd <- suppressMessages(SummarizedExperiment::rowData(se))
    cd <- suppressMessages(SummarizedExperiment::colData(se))
    canonical_gene_ids <- rownames(se)
    canonical_sample_ids <- colnames(se)
    # Do not impose canonical dimnames on the native assay or copy its values.
    native_names <- dimnames(counts)
    if (!is.null(native_names[[1L]]) &&
        !identical(native_names[[1L]], canonical_gene_ids))
      qc_stop("Stored assay row names and rowData are not exactly aligned.")
    if (!is.null(native_names[[2L]]) &&
        !identical(native_names[[2L]], canonical_sample_ids))
      qc_stop("Stored assay column names and colData are not exactly aligned.")
    if (nrow(rd) != n_genes || !identical(rownames(rd), canonical_gene_ids))
      qc_stop("rowData and assay rows are not exactly aligned.")
    if (nrow(cd) != n_samples || !identical(rownames(cd), canonical_sample_ids))
      qc_stop("colData and assay columns are not exactly aligned.")
    if (is.null(canonical_gene_ids) || is.null(canonical_sample_ids) ||
        length(canonical_gene_ids) != n_genes || length(canonical_sample_ids) != n_samples)
      qc_stop("Canonical gene or sample identifiers are absent or have incorrect lengths.")
    if (!all(c("gene_id", "gene_name", "gene_type") %in% names(rd)) ||
        !all(c("patient", "sample_type") %in% names(cd)))
      qc_stop("Required gene or sample metadata columns are missing.")
    field <- function(data, name, expected_length) {
      value <- data[[name]]
      if (!(is.character(value) || is.factor(value)) || length(value) != expected_length)
        qc_stop("Required annotation field has an incompatible type or length.")
      as.character(value)
    }
    gene_id <- field(rd, "gene_id", n_genes)
    gene_name <- field(rd, "gene_name", n_genes)
    gene_type <- field(rd, "gene_type", n_genes)
    patient_id <- field(cd, "patient", n_samples)
    sample_type <- field(cd, "sample_type", n_samples)
    # Release the object reference after extraction so unused assays can be
    # reclaimed; counts and annotation fields remain unchanged.
    rm(se)
    sample_id <- canonical_sample_ids
    missing <- qc_missing
    duplicate <- function(value) {
      valid <- !missing(value)
      valid & (duplicated(value) | duplicated(value, fromLast = TRUE))
    }
    sample_missing <- missing(sample_id)
    sample_duplicate <- duplicate(sample_id)
    patient_missing <- missing(patient_id)
    gene_id_missing <- missing(gene_id)
    gene_id_duplicate <- duplicate(gene_id)
    gene_name_missing <- missing(gene_name)
    gene_type_missing <- missing(gene_type)
    gene_name_duplicate <- duplicate(gene_name)
    suffix <- !gene_id_missing & grepl("\\.[0-9]+$", gene_id)

    # Validate and accumulate one column at a time. Numeric accumulators avoid
    # integer overflow in totals; no expression data or full logical copy is changed.
    library_size <- numeric(n_samples)
    detected <- integer(n_samples)
    gene_total <- numeric(n_genes)
    nonzero <- integer(n_genes)
    for (j in seq_len(n_samples)) {
      column <- counts[, j]
      if (!is.numeric(column)) qc_stop("Raw counts must be numeric.")
      if (anyNA(column)) qc_stop("Raw counts contain missing values.")
      count_range <- range(column)
      if (any(!is.finite(count_range))) qc_stop("Raw counts contain non-finite values.")
      if (count_range[[1L]] < 0) qc_stop("Raw counts contain negative values.")
      if (any(column != floor(column))) qc_stop("Raw counts are not integer-like.")
      expressed <- column > 0
      library_size[[j]] <- sum(column)
      detected[[j]] <- sum(expressed)
      gene_total <- gene_total + column
      nonzero <- nonzero + expressed
    }
    if (any(!is.finite(library_size)) || any(!is.finite(gene_total)))
      qc_stop("Count totals exceed the finite numeric range.")
    summary$raw_count_validation <- "numeric, integer-like, finite, non-missing, non-negative"

    patient_counts <- table(patient_id[!patient_missing])
    samples_per_patient <- as.integer(patient_counts[match(patient_id, names(patient_counts))])
    primary <- !missing(sample_type) & sample_type == "Primary Tumor"
    primary_patient_counts <- table(patient_id[primary & !patient_missing])
    multiple <- primary_patient_counts[primary_patient_counts > 1L]
    sample_qc <- data.frame(
      sample_index = seq_len(n_samples), sample_id = sample_id, patient_id = patient_id,
      sample_type = sample_type, library_size = library_size,
      detected_gene_count = detected, detected_gene_proportion = detected / n_genes,
      zero_total_sample = library_size == 0, sample_id_missing = sample_missing,
      sample_id_duplicated = sample_duplicate, patient_id_missing = patient_missing,
      samples_per_patient = samples_per_patient,
      patient_has_multiple_samples = samples_per_patient > 1L, stringsAsFactors = FALSE
    )
    gene_qc <- data.frame(
      gene_index = seq_len(n_genes), gene_id = gene_id, gene_name = gene_name,
      gene_type = gene_type, total_count = gene_total, nonzero_sample_count = nonzero,
      nonzero_sample_proportion = nonzero / n_samples, all_zero_gene = nonzero == 0L,
      gene_id_missing = gene_id_missing, gene_name_missing = gene_name_missing,
      gene_type_missing = gene_type_missing, gene_id_duplicated = gene_id_duplicate,
      gene_name_duplicated = gene_name_duplicate, ensembl_version_suffix = suffix,
      stringsAsFactors = FALSE
    )
    multiple_qc <- data.frame(patient_id = names(multiple),
      primary_tumor_sample_count = as.integer(multiple), stringsAsFactors = FALSE)

    summary$number_of_patients <- length(patient_counts)
    # Unexpected sample-type values remain in external sample_qc.tsv only.
    summary$sample_type_distribution <- list(
      primary_tumor = sum(primary), missing = sum(missing(sample_type)),
      other = sum(!missing(sample_type) & !primary))
    summary$gene_type_distribution <- qc_gene_type_counts(gene_type)
    summary$zero_total_sample_count <- sum(library_size == 0)
    summary$all_zero_gene_count <- sum(nonzero == 0L)
    summary$multiple_sample_patient_count <- length(multiple)
    # Duplicated counts mean all rows participating in a duplicate group.
    summary$identifier_counts <- list(
      missing_sample_id = sum(sample_missing), duplicated_sample_id_rows = sum(sample_duplicate),
      duplicated_sample_id_values = length(unique(sample_id[sample_duplicate])),
      missing_patient_id = sum(patient_missing), missing_gene_id = sum(gene_id_missing),
      duplicated_gene_id_rows = sum(gene_id_duplicate),
      duplicated_gene_id_values = length(unique(gene_id[gene_id_duplicate])),
      missing_gene_name = sum(gene_name_missing), missing_gene_type = sum(gene_type_missing),
      duplicated_gene_name_rows = sum(gene_name_duplicate),
      duplicated_gene_name_values = length(unique(gene_name[gene_name_duplicate])))
    summary$ensembl_version_suffix_count <- sum(suffix)
    summary$ensembl_version_suffix_proportion <- sum(suffix) / n_genes

    # Count-valid and structurally aligned diagnostics remain useful even when
    # identifier, sample-type or zero-library checks subsequently fail.
    write_tsv(sample_qc, "sample_qc.tsv")
    summary$completed_output_filenames <- c(summary$completed_output_filenames, "sample_qc.tsv")
    write_tsv(gene_qc, "gene_qc.tsv")
    summary$completed_output_filenames <- c(summary$completed_output_filenames, "gene_qc.tsv")
    write_tsv(multiple_qc, "multiple_samples_per_patient.tsv")
    summary$completed_output_filenames <- c(summary$completed_output_filenames,
                                          "multiple_samples_per_patient.tsv")
    for (name in names(summary$identifier_counts))
      log_value(name, summary$identifier_counts[[name]])
    log_value("Patients", summary$number_of_patients)
    log_value("Zero-total samples", summary$zero_total_sample_count)
    log_value("All-zero genes", summary$all_zero_gene_count)
    log_value("Patients with multiple Primary Tumor samples", length(multiple))
    log_value("Ensembl version suffix count", sum(suffix))
    log_value("Ensembl version suffix proportion", sum(suffix) / n_genes)

    for (name in c("gene_name", "gene_type")) {
      count <- summary$identifier_counts[[paste0("missing_", name)]]
      if (count > 0L) {
        text <- paste("Missing", name, "values:", count)
        summary$warnings <- c(summary$warnings, text)
        warning(structure(list(message = text, call = NULL),
                          class = c("qc_safe_warning", "warning", "condition")))
      }
    }
    failed <- c(
      "Missing or empty sample identifiers." = any(sample_missing),
      "Duplicated sample identifiers." = any(sample_duplicate),
      "Missing or empty patient identifiers." = any(patient_missing),
      "Missing or empty gene_id." = any(gene_id_missing),
      "Duplicated gene_id." = any(gene_id_duplicate),
      "Missing or empty canonical gene identifiers." = any(missing(canonical_gene_ids)),
      "Retained sample types are not all Primary Tumor." = any(!primary),
      "Zero-total samples detected." = any(library_size == 0))
    summary$fatal_conditions <- names(failed)[failed]
    if (any(failed)) qc_stop(paste(summary$fatal_conditions, collapse = " "))
    TRUE
  }, warning = function(warning) {
    text <- if (inherits(warning, "qc_safe_warning")) conditionMessage(warning) else
      "Unexpected package or I/O warning; underlying text suppressed to protect identifiers."
    warning_count <<- warning_count + 1L
    log_value("Warning", text)
    invokeRestart("muffleWarning")
  }, message = function(message) {
    if (!inherits(message, "qc_safe_message")) invokeRestart("muffleMessage")
  }), error = function(error) {
    summary$qc_status <<- "failed"
    summary$failure_reason <<- safe_error_text(error)
    tryCatch(log_value("Failure", safe_error_text(error)), error = function(error) NULL)
    FALSE
  }, interrupt = function(interrupt) {
    summary$qc_status <<- "interrupted"
    summary$failure_reason <<- "Execution interrupted."
    tryCatch(log_value("Status", "interrupted"), error = function(error) NULL)
    FALSE
  })

  summary$warning_count <- warning_count
  # Finalize provenance even after a validation failure. A failed write must
  # never result in a successful process exit or a claimed complete QC run.
  session_ok <- tryCatch({
    atomic_write("session_info.txt", function(path)
      writeLines(capture.output(suppressMessages(utils::sessionInfo())), path))
    TRUE
  }, error = function(error) FALSE, interrupt = function(interrupt) {
    summary$qc_status <<- "interrupted"
    summary$failure_reason <<- "Session information writing interrupted."
    FALSE
  })
  if (session_ok) summary$completed_output_filenames <- c(summary$completed_output_filenames,
                                                        "session_info.txt") else {
    outcome <- FALSE
    if (summary$qc_status != "interrupted") {
      summary$qc_status <- "failed"
      summary$failure_reason <- "Could not write session information."
    }
  }
  qc_finalize(summary, outcome, log_value, close_log,
    write_summary = function(value) atomic_write("qc_summary.yml", function(path)
      yaml::write_yaml(value, path)), utc_now = function() utc(Sys.time()))
}

# Suppress arbitrary condition text outside the run log as well. Before output
# initialization, failures cannot produce run artifacts and are reported safely.
exit_status <- tryCatch(withCallingHandlers(main(), warning = function(warning) {
  message(structure(list(
    message = "Startup warning; underlying text suppressed to protect local configuration.\n",
    call = NULL), class = c("qc_safe_message", "message", "condition")))
  invokeRestart("muffleWarning")
}, message = function(message) {
  if (!inherits(message, "qc_safe_message")) invokeRestart("muffleMessage")
}), error = function(error) {
  message(safe_error_text(error))
  1L
}, interrupt = function(interrupt) {
  message("Execution interrupted before QC finalization.")
  1L
})
quit(save = "no", status = exit_status)
