#!/usr/bin/env Rscript
# Schema Update Script
# This script regenerates schema files from the data dictionary CSV
#
# Usage:
#   Rscript inst/scripts/update_schema.R [version]
#   
#   If version is not provided, it will auto-increment the patch version
#
# Example:
#   Rscript inst/scripts/update_schema.R 1.2.0

library(yaml)

# Source the schema functions
source("R/loadSchema.R")

# Get command line arguments
args <- commandArgs(trailingOnly = TRUE)

# Read the current schema to get version
current_schema_file <- "inst/schema/cmd_data_dictionary.yaml"
if (file.exists(current_schema_file)) {
  current_schema <- yaml::read_yaml(current_schema_file)
  current_version <- current_schema$schema_info$version
  cat("Current schema version:", current_version, "\n")
} else {
  current_version <- "1.0.0"
  cat("No existing schema found. Starting with version:", current_version, "\n")
}

# Determine new version
if (length(args) > 0) {
  new_version <- args[1]
  cat("Using provided version:", new_version, "\n")
} else {
  # Auto-increment patch version
  version_parts <- as.numeric(strsplit(current_version, "\\.")[[1]])
  version_parts[3] <- version_parts[3] + 1
  new_version <- paste(version_parts, collapse = ".")
  cat("Auto-incrementing to version:", new_version, "\n")
}

# Read data dictionary
dict_file <- "inst/schema/cmd_data_dictionary.csv"
if (!file.exists(dict_file)) {
  stop("Data dictionary not found at: ", dict_file)
}

cat("\nReading data dictionary from:", dict_file, "\n")
dict <- read.csv(dict_file, stringsAsFactors = FALSE)
cat("Loaded", nrow(dict), "field definitions\n")

# Generate YAML schema
cat("\nGenerating YAML schema...\n")
tableToYamlSchema(
  dict,
  schema_version = new_version,
  schema_name = "curatedMetagenomicData_metadata_schema",
  schema_description = "Metadata schema for curatedMetagenomicData package",
  output_file = "inst/schema/cmd_data_dictionary.yaml"
)

# Generate LinkML schema
cat("\nGenerating LinkML schema...\n")
tableToLinkmlSchema(
  dict,
  schema_id = "https://github.com/waldronlab/curatedMetagenomicData",
  schema_name = "curatedMetagenomicData",
  schema_version = new_version,
  schema_description = "Metadata schema for curatedMetagenomicData package",
  output_file = "inst/schema/cmd_data_dictionary_linkml.yaml"
)

# Create versioned backup
backup_yaml <- paste0("inst/schema/archive/cmd_schema_v", new_version, ".yaml")
backup_linkml <- paste0("inst/schema/archive/cmd_schema_v", new_version, ".linkml.yaml")

if (!dir.exists("inst/schema/archive")) {
  dir.create("inst/schema/archive", recursive = TRUE)
  cat("\nCreated archive directory\n")
}

file.copy("inst/schema/cmd_data_dictionary.yaml", backup_yaml, overwrite = TRUE)
file.copy("inst/schema/cmd_data_dictionary_linkml.yaml", backup_linkml, overwrite = TRUE)

cat("\nVersioned backups created:\n")
cat("  -", backup_yaml, "\n")
cat("  -", backup_linkml, "\n")

cat("\n✓ Schema update complete!\n")
cat("\nNext steps:\n")
cat("  1. Review the generated schema files\n")
cat("  2. Test with validation functions\n")
cat("  3. Commit changes to version control\n")
cat("\nFiles updated:\n")
cat("  - inst/schema/cmd_data_dictionary.yaml\n")
cat("  - inst/schema/cmd_data_dictionary_linkml.yaml\n")
