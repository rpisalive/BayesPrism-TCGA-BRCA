#!/usr/bin/env Rscript

# Acquire sTIL-matched TCGA-BRCA Primary Tumor STAR - Counts data.
# Run with: Rscript scripts/01_acquire_tcga_bulk.R

main <- function() {
  packages <- c("TCGAbiolinks", "SummarizedExperiment", "yaml")
  for (pkg in packages) if (!requireNamespace(pkg, quietly = TRUE))
    stop("Required package is not installed: ", pkg, call. = FALSE)

  script_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  script_path <- if (length(script_arg) == 1L) normalizePath(
    sub("^--file=", "", script_arg), winslash = "/", mustWork = TRUE) else NULL
  project_root <- if (is.null(script_path)) normalizePath(getwd(), winslash = "/", mustWork = TRUE) else
    normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE)
  config_file <- file.path(project_root, "config", "local", "paths.yml")
  if (!file.exists(config_file)) stop("Missing configuration: ", config_file,
    ". Copy config/paths.example.yml to config/local/paths.yml.", call. = FALSE)
  config <- yaml::read_yaml(config_file, eval.expr = FALSE)
  keys <- c("project_data_root", "raw_data_dir", "processed_data_dir",
            "intermediate_data_dir", "tcga_data_dir", "stil_scoring_file")
  for (key in keys) if (!is.character(config[[key]]) || length(config[[key]]) != 1L ||
    is.na(config[[key]]) || !nzchar(config[[key]]) || grepl("/path/to/", config[[key]], fixed = TRUE))
    stop("Missing or placeholder configuration setting: ", key, call. = FALSE)

  absolute <- function(path) grepl("^(/|[A-Za-z]:[/\\\\]|\\\\\\\\)", path)
  resolve <- function(path) normalizePath(if (absolute(path)) path else file.path(project_root, path),
                                          winslash = "/", mustWork = TRUE)
  within <- function(path, parent) {
    if (.Platform$OS.type == "windows") { path <- tolower(path); parent <- tolower(parent) }
    parent <- sub("/+$", "", parent)
    identical(path, parent) || startsWith(path, paste0(parent, "/"))
  }
  paths <- lapply(config[setdiff(keys, "stil_scoring_file")], resolve)
  if (within(paths$project_data_root, project_root) || within(project_root, paths$project_data_root))
    stop("project_data_root must be separate from the repository.", call. = FALSE)
  for (key in setdiff(names(paths), "project_data_root")) if (!within(paths[[key]], paths$project_data_root) ||
    identical(paths[[key]], paths$project_data_root)) stop(key, " must be below project_data_root.", call. = FALSE)
  if (!within(paths$tcga_data_dir, paths$raw_data_dir) || identical(paths$tcga_data_dir, paths$raw_data_dir))
    stop("tcga_data_dir must be below raw_data_dir.", call. = FALSE)
  stil_file <- resolve(config$stil_scoring_file)
  if (dir.exists(stil_file) || within(stil_file, project_root))
    stop("stil_scoring_file must be a patient-level CSV outside the repository.", call. = FALSE)

  date_utc <- format(Sys.time(), "%Y-%m-%d", tz = "UTC")
  run_id <- paste0(format(Sys.time(), "%Y%m%dT%H%M%S", tz = "UTC"), "_", Sys.getpid())
  processed_dir <- file.path(paths$processed_data_dir, "tcga_brca", run_id)
  intermediate_dir <- file.path(paths$intermediate_data_dir, "tcga_brca", run_id)
  for (path in c(processed_dir, intermediate_dir)) if (!dir.create(path, recursive = TRUE, showWarnings = FALSE) && !dir.exists(path))
    stop("Could not create output directory: ", path, call. = FALSE)
  log_file <- file(file.path(intermediate_dir, "acquisition.log"), "wt")
  on.exit(close(log_file), add = TRUE)
  log_value <- function(name, value) { line <- paste0(name, ": ", paste(value, collapse = ", ")); message(line); writeLines(line, log_file) }
  report_ids <- function(ids, filename, label) {
    utils::write.csv(data.frame(patient_id = ids), file.path(intermediate_dir, filename), row.names = FALSE)
    log_value(paste0(label, " count"), length(ids))
  }

  query_parameters <- list(project = "TCGA-BRCA", data.category = "Transcriptome Profiling",
    data.type = "Gene Expression Quantification", workflow.type = "STAR - Counts",
    experimental.strategy = "RNA-Seq", access = "open")
  versions <- vapply(packages, function(pkg) as.character(utils::packageVersion(pkg)), character(1))
  log_value("Retrieval date (UTC)", date_utc)
  for (name in names(query_parameters)) log_value(name, query_parameters[[name]])
  log_value("Download sample type", "Primary Tumor")
  log_value("R version", R.version.string)
  for (pkg in names(versions)) log_value(paste(pkg, "version"), versions[[pkg]])

  # Preserve the existing discovery query and exact sTIL intersection logic.
  query_brca <- do.call(TCGAbiolinks::GDCquery, c(query_parameters, list(
    sample.type = c("Primary Tumor", "Solid Tissue Normal"))))
  results_brca <- TCGAbiolinks::getResults(query_brca)
  unique_id <- unique(as.character(results_brca$cases.submitter_id))
  if (anyNA(unique_id) || any(!nzchar(unique_id))) stop("Discovery query contains missing patient identifiers.", call. = FALSE)
  stil <- utils::read.csv(stil_file, stringsAsFactors = FALSE,
                          check.names = FALSE)
  names(stil) <- sub(
    "^\xef\xbb\xbf",
    "",
    names(stil),
    useBytes = TRUE
  )

  if (!"ID" %in% names(stil)) {
    stop("The sTIL scoring CSV must contain an ID column.", call. = FALSE)
  }
  stil$ID <- as.character(stil$ID)
  if (anyNA(stil$ID) || any(!nzchar(stil$ID))) stop("The sTIL ID column contains missing or empty identifiers.", call. = FALSE)
  common_ids <- intersect(unique_id, stil$ID)
  missing_in_stil <- setdiff(unique_id, stil$ID)
  missing_in_brca <- setdiff(stil$ID, unique_id)
  download_ids <- intersect(unique_id, stil$ID)
  log_value("TCGA patients before sTIL filtering", length(unique_id))
  log_value("sTIL IDs", length(stil$ID)); log_value("Overlapping IDs", length(common_ids)); log_value("Requested IDs", length(download_ids))
  report_ids(download_ids, "requested_patient_ids.csv", "Requested IDs")
  report_ids(missing_in_stil, "tcga_ids_missing_in_stil.csv", "TCGA IDs absent from sTIL")
  report_ids(missing_in_brca, "stil_ids_missing_in_tcga.csv", "sTIL IDs absent from TCGA")
  if (!length(download_ids)) stop("No overlapping TCGA and sTIL patient IDs were found.", call. = FALSE)

  query_brca_stil <- do.call(TCGAbiolinks::GDCquery, c(query_parameters, list(
    sample.type = "Primary Tumor", barcode = download_ids)))
  results_brca_stil <- TCGAbiolinks::getResults(query_brca_stil)
  if (!nrow(results_brca_stil)) stop("The sTIL-matched Primary Tumor query returned no files.", call. = FALSE)
  query_ids <- unique(as.character(results_brca_stil$cases.submitter_id))
  if (anyNA(query_ids) || any(!nzchar(query_ids))) stop("Primary-tumor query contains missing patient identifiers.", call. = FALSE)
  report_ids(setdiff(download_ids, query_ids), "requested_ids_missing_from_query.csv", "Requested IDs absent from primary-tumor query")
  if (length(setdiff(query_ids, download_ids))) stop("The query returned patients outside the requested sTIL cohort.", call. = FALSE)
  manifest_columns <- intersect(c("file_id", "file_name", "file_size", "md5sum", "cases.submitter_id", "cases"), names(results_brca_stil))
  utils::write.csv(results_brca_stil[, manifest_columns, drop = FALSE], file.path(intermediate_dir, "gdc_manifest.csv"), row.names = FALSE)
  saveRDS(query_brca_stil, file.path(intermediate_dir, "sTIL_primary_tumor_query.rds"))

  # Use the explicit external GDC download directory for preparation.
  # Source files are not removed by this call because save = FALSE.
  # Keep any TCGAbiolinks-generated manifest with this run's external
  # intermediate artifacts, then restore the caller's working directory.
  original_working_directory <- getwd()
  tryCatch(
    {
      setwd(intermediate_dir)
      TCGAbiolinks::GDCdownload(
        query_brca_stil,
        method = "api",
        files.per.chunk = 20,
        directory = paths$tcga_data_dir
      )
    },
    finally = setwd(original_working_directory)
  )
  brca_stil_se <- TCGAbiolinks::GDCprepare(
    query_brca_stil,
    directory = paths$tcga_data_dir,
    summarizedExperiment = TRUE,
    save = FALSE
  )
  if (!methods::is(brca_stil_se, "SummarizedExperiment")) stop("GDCprepare did not return a SummarizedExperiment.", call. = FALSE)
  if (!"unstranded" %in% SummarizedExperiment::assayNames(brca_stil_se)) stop("Required raw-count assay 'unstranded' is absent.", call. = FALSE)
  raw_counts <- SummarizedExperiment::assay(brca_stil_se, "unstranded")
  if (!is.numeric(raw_counts)) {
    stop("Counts must be numeric.", call. = FALSE)
  }
  if (anyNA(raw_counts)) {
    stop("Counts must not contain missing values.", call. = FALSE)
  }
  if (!nrow(raw_counts) || !ncol(raw_counts)) {
    stop("The raw-count matrix has zero genes or samples.", call. = FALSE)
  }

  count_range <- range(raw_counts)
  if (any(!is.finite(count_range)) || count_range[[1L]] < 0) {
    stop("Counts must be finite and non-negative.", call. = FALSE)
  }

  gene_metadata <- as.data.frame(SummarizedExperiment::rowData(brca_stil_se))
  sample_metadata <- as.data.frame(SummarizedExperiment::colData(brca_stil_se))
  required_gene_columns <- c("gene_id", "gene_name", "gene_type")
  if (!all(required_gene_columns %in% names(gene_metadata))) stop("Gene metadata lacks required columns.", call. = FALSE)
  if (nrow(gene_metadata) != nrow(raw_counts) || !identical(rownames(gene_metadata), rownames(raw_counts))) stop("Gene metadata and count-matrix rows are not exactly aligned.", call. = FALSE)
  if (nrow(sample_metadata) != ncol(raw_counts) || !identical(rownames(sample_metadata), colnames(raw_counts))) stop("Sample metadata and count-matrix columns are not exactly aligned.", call. = FALSE)
  gene_ids <- rownames(raw_counts); sample_ids <- colnames(raw_counts)
  if (is.null(gene_ids) || anyNA(gene_ids) || any(!nzchar(gene_ids))) stop("Count-matrix gene identifiers are missing.", call. = FALSE)
  if (is.null(sample_ids) || anyNA(sample_ids) || any(!nzchar(sample_ids))) stop("Count-matrix sample identifiers are missing.", call. = FALSE)
  duplicated_sample_ids <- unique(sample_ids[duplicated(sample_ids)])
  utils::write.csv(data.frame(sample_id = duplicated_sample_ids), file.path(intermediate_dir, "duplicated_sample_ids.csv"), row.names = FALSE)
  log_value("Duplicated sample identifiers", length(duplicated_sample_ids))
  if (length(duplicated_sample_ids)) {
    stop("Duplicated sample identifiers detected; no samples were discarded.", call. = FALSE)
  }
  if (any(!grepl("^TCGA-[A-Za-z0-9]{2}-[A-Za-z0-9]{4}-", sample_ids))) stop("Sample identifiers are not recognizable TCGA sample barcodes.", call. = FALSE)

  recovered_patient_ids <- unique(substr(sample_ids, 1L, 12L))
  recovered_samples_per_patient <- table(substr(sample_ids, 1L, 12L))
  multi_sample_patients <- recovered_samples_per_patient[
    recovered_samples_per_patient > 1L
  ]

  utils::write.csv(
    data.frame(
      patient_id = names(multi_sample_patients),
      recovered_primary_tumor_sample_count = as.integer(multi_sample_patients),
      row.names = NULL,
      check.names = FALSE
    ),
    file.path(intermediate_dir, "patients_with_multiple_primary_tumor_samples.csv"),
    row.names = FALSE
  )

  log_value("Patients with multiple Primary Tumor samples",
            length(multi_sample_patients))

  missing_recovered_ids <- setdiff(download_ids, recovered_patient_ids)
  report_ids(missing_recovered_ids, "requested_ids_not_recovered.csv", "Requested patient IDs not recovered")
  if (length(setdiff(recovered_patient_ids, download_ids))) stop("Prepared data contain patients outside the requested sTIL cohort.", call. = FALSE)
  if (length(missing_recovered_ids)) warning("Some requested patients were not recovered; see requested_ids_not_recovered.csv.", call. = FALSE)
  log_value("Recovered patients", length(recovered_patient_ids)); log_value("Recovered samples", ncol(raw_counts)); log_value("Genes", nrow(raw_counts))

  raw_counts_export <- data.frame(gene_id = gene_ids, gene_name = gene_metadata$gene_name,
    gene_type = gene_metadata$gene_type, raw_counts, check.names = FALSE)
  sample_metadata_csv <- sample_metadata
  list_columns <- vapply(sample_metadata_csv, is.list, logical(1))
  sample_metadata_csv[list_columns] <- lapply(sample_metadata_csv[list_columns], function(column)
    vapply(column, function(value) if (!length(value)) NA_character_ else paste(as.character(unlist(value)), collapse = ";"), character(1)))
  sample_metadata_csv <- data.frame(count_matrix_sample_id = sample_ids, sample_metadata_csv, check.names = FALSE)
  prefix <- "TCGA_BRCA_sTIL_primary_tumor"
  outputs <- c(counts = file.path(processed_dir, paste0(prefix, "_raw_counts.csv")),
    metadata = file.path(processed_dir, paste0(prefix, "_metadata.csv")), se = file.path(processed_dir, paste0(prefix, "_SE.rds")))
  utils::write.csv(raw_counts_export, outputs[["counts"]], row.names = FALSE)
  utils::write.csv(sample_metadata_csv, outputs[["metadata"]], row.names = FALSE)
  saveRDS(brca_stil_se, outputs[["se"]])
  if (anyNA(file.info(outputs)$size) || any(file.info(outputs)$size <= 0)) stop("An expected output is missing or empty.", call. = FALSE)
  saveRDS(list(retrieval_date_utc = date_utc, query_parameters = query_parameters,
    selection_rule = "intersect(unique_id, stil$ID)", requested_ids = download_ids,
    recovered_patient_ids = recovered_patient_ids, recovered_samples = ncol(raw_counts), genes = nrow(raw_counts),
    assay = "unstranded", r_version = R.version.string, package_versions = versions,
    stil_input_md5 = tools::md5sum(stil_file), output_files = outputs), file.path(intermediate_dir, "provenance.rds"))
  writeLines(capture.output(utils::sessionInfo()), file.path(intermediate_dir, "session_info.txt"))
}

main()
