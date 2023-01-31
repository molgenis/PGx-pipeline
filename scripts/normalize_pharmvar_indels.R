#!/usr/bin/env Rscript


# Load libraries
library(data.table)
library(tidyverse)
library(argparse)

# Declare constants
parser <- ArgumentParser(description='normalize indels in pharmvar table.')
parser$add_argument('--pharmvar-table', metavar='file', type = 'character')
parser$add_argument('--reference-indels', metavar='file', type = 'character')
parser$add_argument('--out', metavar='prefix', type = 'character')

# Declare function definitions

# Main

#' Execute main
#' 
#' @param argv A vector of arguments normally supplied via command-line.
main <- function(argv = NULL) {
  if (is.null(argv)) {
    argv <- commandArgs(trailingOnly = T)
  }
  args <- parser$parse_args(argv)

  # Process input
  pharmvar_table <- tibble(fread(args$pharmvar_table, data.table=F))
  reference_indels <- tibble(fread(args$reference_indels, data.table=F, sep="\t"))

  # Perform method
  pharmvar_pivotted <- pharmvar_table %>%
    pivot_longer(
      cols = c("Reference Allele", "Variant Allele"),
      names_to = "Allele Name", values_to = "Alleles") %>%
    group_by(rsID) %>%
    mutate(Indel = case_when(
      Alleles=="-" ~ "Del",
      any(Alleles=="-") ~ "Ins")
    )

  reference_indels_pivotted <- reference_indels %>%
    pivot_longer(
      cols = c("REF", "ALT"),
      names_to = "Allele Name", values_to = "Alleles") %>%
    group_by(ID) %>%
    mutate(
      Indel = case_when(
      max(str_count(Alleles)) == str_count(Alleles) ~ "Ins",
      TRUE ~ "Del",
      `Variant Start` = POS)
    ) %>% select(c("rsID" = "ID", "Indel" = "Indel", "Alleles" = "Alleles"))

  pharmvar_updated <- pharmvar_pivotted %>%
    mutate(
      `Old Alleles` = Alleles,
      `Old Variant Start` = `Variant Start`,
      `Old Variant Stop` = `Variant Stop`,
      `Old Variant Dist` = `Variant Stop` - `Variant Start`) %>%
    rows_update(
      reference_indels_pivotted, by=c("rsID", "Indel"),
      unmatched = "ignore") %>%
    mutate(`Variant Stop` = `Variant Start` + `Old Variant Dist`)

  fwrite(
    pharmvar_updated %>% filter(rsID %in% reference_indels$ID) %>%
      select(c("Haplotype Name", "Gene", "rsID", "Old Alleles", "Alleles", "Old Variant Start", "Variant Start", "Old Variant Stop", "Variant Stop")),
    paste0(args$out, sub('\\.tsv$', '.indels_mapped_inspection.tsv', basename(args$pharmvar_table))),
    sep="\t")

  pharmvar_cleaned <- pharmvar_updated %>%
    select(all_of(colnames(pharmvar_pivotted)), -Indel) %>%
    pivot_wider(names_from = "Allele Name", values_from = "Alleles") %>%
    select(all_of(colnames(pharmvar_table)))

  fwrite(pharmvar_cleaned,
         paste0(args$out, basename(args$pharmvar_table)), sep="\t")

  # Process output
}

if (sys.nframe() == 0 && !interactive()) {
  main()
}