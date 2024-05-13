"""
Created:      19/01/2023
Author:       C.A. (Robert) Warmerdam

Copyright (C) 2023 C.A. Warmerdam

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License can be found in the LICENSE file in the
root directory of this source tree. If not, see <https://www.gnu.org/licenses/>.
"""

# Standard imports.
import os
import sys
import argparse
import re

import IlluminaBeadArrayFiles

import numpy as np
import pandas as pd

from Bio import SeqIO

# Metadata
__program__ = "CNV-caller"
__author__ = "C.A. (Robert) Warmerdam"
__email__ = "c.a.warmerdam@umcg.nl"
__license__ = "GPLv3"
__version__ = 1.0
__description__ = "{} is a program developed and maintained by {}. " \
                  "This program is licensed under the {} license and is " \
                  "provided 'as-is' without any warranty or indemnification " \
                  "of any kind.".format(__program__,
                                        __author__,
                                        __license__)


# Constants
ASSEMBLY_REPORT_NAMES = ["Sequence-Name", "Sequence-Role", "Assigned-Molecule", "Assigned-Molecule-Location/Type",
                         "GenBank-Accn", "Relationship", "RefSeq-Accn", "Assembly-Unit", "Sequence-Length",
                         "UCSC-style-name"]

# Classes

# Functions

# Main


def get_preceding_nucleotide(seq, position, reference, alternative):
    # Reference should match the sequence from position onwards (the length of the reference allele
    #


def main(argv=None):
    if argv is None:
        argv = sys.argv

    # Process input
    argument_parser = argparse.ArgumentParser(
        prog = 'GSA Indel Normalizer',
        description = 'Makes indels parsimonious')

    argument_parser.add_argument('--bim')
    argument_parser.add_argument('--bpm-csv')
    argument_parser.add_argument('--fasta')

    args = argument_parser.parse_args(sys.argv[1:])

    # Load ref sequence
    handle = gzip.open("/groups/umcg-fg/tmp01/projects/pgx-passport/data/public/reference_genome/b37/GCF_000001405.25_GRCh37.p13_genomic.fna.gz", "rt")
    assembly_report = pd.read_table(
        "/groups/umcg-fg/tmp01/projects/pgx-passport/data/public/reference_genome/b37/GCF_000001405.25_GRCh37.p13_assembly_report.txt",
        comment="#", names=ASSEMBLY_REPORT_NAMES)

    # Load manifest
    manifest_data_frame = pd.read_csv(args.bpm_csv, skiprows=7, dtype=str)
    manifest_data_frame = manifest_data_frame.loc[~np.isnan(manifest_data_frame.MapInfo.astype("double")), :]
    manifest_data_frame = manifest_data_frame.astype({"MapInfo": "int"})

    # Load bim file
    bim = pd.read_table(args.bim, header=None, names=["chrom", "name", "position", "bp", "ref", "alt"])
    bim = bim.astype({"chrom":str})

    # Perform method

    # Select indels
    manifest_indels = manifest_data_frame.loc[manifest_data_frame.SNP.isin(["[I/D]", "[D/I]"]), :].copy()
    manifest_indels[['IlmnIDName', 'IlmnIDStrand', 'IlmnIDFwdRev', 'IlmnIDProbeID']] = (
        manifest_indels.IlmnID.str.rsplit("_", n=3, expand=True))
    regex_pattern = r'([ACTGNY]+)\[([ATGCNY-]+)\/([ATGCNY-]+)\]([ACTGNY]+)'
    np.all(manifest_indels.TopGenomicSeq.str.upper().str.fullmatch(regex_pattern))
    manifest_indels[["PrecedingSeq", "AlleleA", "AlleleB", "ProceedingSeq"]] = (
        manifest_indels.TopGenomicSeq
        .str.upper()
        .str.extract(regex_pattern, expand=True)).astype(str)

    manifest_indels["SequenceA"] = (
            manifest_indels["PrecedingSeq"] + manifest_indels["AlleleA"] + manifest_indels["ProceedingSeq"])
    manifest_indels["SequenceB"] = (
            manifest_indels["PrecedingSeq"] + manifest_indels["AlleleB"] + manifest_indels["ProceedingSeq"])

    bim_indels = bim.loc[bim.ref.isin(["I", "D"]), ].copy()

    # Merge indels based on SNP ID
    print("Number of indels in .bim file:", len(bim_indels))
    print("Number of indels in manifest file:", len(manifest_indels))
    indels_merged = bim_indels.merge(
        manifest_indels, how="inner",
        left_on=["name"], right_on=["Name"], validate="1:1")
    print("Number of overlapping indels (should match with the number in the .bim file):", len(indels_merged))

    # indels_merged.loc[indels_merged.ref == "I", "refUpdated"] = (
    #     indels_merged.loc[indels_merged.ref == "I", "TopGenomicSeqAlleleA"])
    # indels_merged.loc[indels_merged.ref == "D", "refUpdated"] = (
    #     indels_merged.loc[indels_merged.ref == "D", "TopGenomicSeqAlleleB"])
    #
    # indels_merged.loc[indels_merged.alt == "I", "altUpdated"] = (
    #     indels_merged.loc[indels_merged.alt == "I", "TopGenomicSeqAlleleA"])
    # indels_merged.loc[indels_merged.alt == "D", "altUpdated"] = (
    #     indels_merged.loc[indels_merged.alt == "D", "TopGenomicSeqAlleleB"])

    indels_merged[["refSeq"]] = ""

    # Attempt to find the genomic seq for both alleles in the reference genome
    # If the reference genome has the

    for seq_record in SeqIO.parse(handle, "fasta"):
        chromosome = assembly_report.loc[assembly_report["RefSeq-Accn"] == seq_record.id, "Sequence-Name"].values[0]
        print("Chromosome:", chromosome)
        indels_merged.loc[indels_merged.Chr == chromosome, "refSeq"] = (
            indels_merged.loc[indels_merged.Chr == chromosome,:].apply(
                lambda row: seq_record.seq[
                               (row["bp"] - len(row["PrecedingSeq"]))
                               :(row["bp"] + len(row["AlleleB"]) + len(row["ProceedingSeq"]))], axis=1))

    # Now attempt to update the alleles by appending one basepair from the fasta

    # Output
    return 0


if __name__ == "__main__":
    sys.exit(main())
