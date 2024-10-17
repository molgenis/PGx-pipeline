#!/usr/bin/env Rscript


# Load libraries
library(data.table)
library(tidyverse)
library(argparse)

# Declare constants

# Create an ArgumentParser object
parser <- ArgumentParser(description = "QC autosomes script")

# Add arguments to the parser
parser$add_argument(
  "--sample-missingness",
  type = "character",
  required = TRUE,
  help = "Path to the sample missingness file (e.g., qc_input_plink_dataset.smiss)"
)

parser$add_argument(
  "--heterozygosity",
  type = "character",
  required = TRUE,
  help = "Path to the heterozygosity file (e.g., qc_input_plink_dataset.het)"
)

parser$add_argument(
  "--out-prefix",
  type = "character",
  required = TRUE,
  help = "Prefix for the output files (e.g., qc_out)"
)

parser$add_argument(
  "--missingness-threshold",
  type = "double",
  default = 0.03,
  help = "Threshold for sample missingness (default: 0.03)"
)

parser$add_argument(
  "--heterozygosity-threshold",
  type = "double",
  default = 4,
  help = "Threshold for heterozygosity in terms of standard deviations (default: 4)"
)


# Declare function definitions

# Main

#' Execute main
#' 
#' @param argv A vector of arguments normally supplied via command-line.
main <- function(argv = NULL) {
  if (is.null(argv)) {
    argv <- commandArgs(trailingOnly = T)
  }
  # Process input

  # Parse the command-line arguments
  args <- parser$parse_args()

  # Access the arguments
  sample_missingness <- args$sample_missingness
  heterozygosity <- args$heterozygosity
  out_prefix <- args$out_prefix
  missingness_threshold <- args$missingness_threshold
  heterozygosity_threshold <- args$heterozygosity_threshold

  # Print arguments for verification
  cat("Sample Missingness File: ", sample_missingness, "\n")
  cat("Heterogeneity File: ", heterozygosity, "\n")
  cat("Output Prefix: ", out_prefix, "\n")
  cat("Missingness Threshold: ", missingness_threshold, "\n")
  cat("Heterozygosity Threshold (in SD): ", heterozygosity_threshold, "\n")

  # Perform method
  het <- fread(heterozygosity, header = TRUE, keepLeadingZeros = TRUE, colClasses = list(character = c(1, 2)))
  missingness <- fread(sample_missingness, header = TRUE, keepLeadingZeros = TRUE, colClasses = list(character = c(1, 2)))

  sample_qc_status <- inner_join(het, missingness, by=c("#FID", "IID"), suffix=c("_het", "_smiss")) %>%
    mutate(het_rate = (OBS_CT_het - `O(HOM)`) / OBS_CT_het,
           het_failed =
             het_rate < (mean(het_rate) - heterozygosity_threshold * sd(het_rate))
             | het_rate > (mean(het_rate) + heterozygosity_threshold * sd(het_rate)),
           missingness_failed = F_MISS > missingness_threshold
    )

  fwrite(sample_qc_status, paste0(out_prefix, ".sample_qc_report.txt"), sep="\t", row.names = F, col.names = T)
  fwrite(sample_qc_status %>% filter(!het_failed, !missingness_failed) %>% select(c('#FID', 'IID')), paste0(out_prefix, ".samples_passed_qc.txt"), sep="\t", row.names = F, col.names = F)

  # Process output
}

if (sys.nframe() == 0 && !interactive()) {
  main()
}
