#!/usr/bin/env Rscript

## ----
## Author:  C.A. (Robert) Warmerdam
## Email:   c.a.warmerdam@umcg.nl
##
## Copyright (c) C.A. Warmerdam, 2022
## 
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## A copy of the GNU General Public License can be found in the LICENSE file in the
## root directory of this source tree. If not, see <https://www.gnu.org/licenses/>.
## ----

# Load libraries
library(tidyverse)
library(argparse)

# Declare constants
parser <- ArgumentParser(description='Join samples in a samplesheet to ugli samples')
parser$add_argument('--samplesheet', metavar='file', type = 'character',
                    help='Samplesheet with samples for whom data should be extracted')
parser$add_argument('--mapping', metavar='file', type = 'character',
                    help='Mapping file for converting samplesheet IDs to genotype data IDs')
parser$add_argument('--gid-col', type = 'character', 
                    help = 'Column wherein ids are listed as present in the genotype data.')
parser$add_argument('--sid-col', type = 'character',
                    help = 'Column wherein ids are listed as present in the samplesheet.')
parser$add_argument('--out', type = 'character')

# Declare function definitions

# Main

#' Execute main
#' 
#' @param argv A vector of arguments normally supplied via command-line.
main <- function(argv=NULL) {
  if (is.null(argv)) {
    argv <- commandArgs(trailingOnly = T)
  }
  # Process input
  args <- parser$parse_args(argv)
  
  samplesheet_table <- read_csv(args$samplesheet)
  sample_mapping <- read_tsv(args$mapping) %>%
    select(c("IID"=args$gid_col, "Sample_ID"=args$sid_col)) %>% 
    inner_join(samplesheet_table, by="Sample_ID") %>%
    mutate(FID = IID) %>%
    select(FID, IID, Sample_ID)

  samples_out <- sample_mapping %>%
    select(FID, IID)

  raw_samples_out <- sample_mapping %>%
    select(Sample_ID)
  
  print(samples_out)

  # Process output
  write.table(raw_samples_out, paste(args$out, "samples.txt", sep = "."), col.names = F, row.names = F, quote = F, sep = "\t")
  write.table(samples_out, paste(args$out, "geno.txt", sep = "."), col.names = F, row.names = F, quote = F, sep = "\t")
  write.table(sample_mapping, paste(args$out, "map.txt", sep = "."), col.names = T, row.names = F, quote = F, sep = "\t")
}

if (sys.nframe() == 0 && !interactive()) {
  main()
}
