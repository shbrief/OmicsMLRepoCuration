# Schema Update and Maintenance Guide

This directory contains the metadata schema definitions for the OmicsMLRepoCuration package.

## Files

### Source of Truth
- **`cmd_data_dictionary.csv`** - Master data dictionary. Edit should be done 
only in the Google Sheet.

### Generated Schema Files
- **`cmd_schema.yaml`** - Custom YAML schema format (generated from CSV)
- **`cmd_schema.linkml.yaml`** - LinkML-compatible schema (generated from CSV)

### Archive
- **`archive/`** - Versioned schema snapshots (auto-generated)

---

## Quick Start: Updating the Schema

### 1. Edit the Data Dictionary

Edit `cmd_data_dictionary.csv` to add, modify, or remove fields:

```csv
col.name,col.class,unique,required,multiplevalues,description,allowedvalues,...
new_field,character,non-unique,optional,FALSE,"Field description","value1|value2",...
```

### 2. Run the Update Script

**Auto-increment patch version:**
```bash
Rscript inst/scripts/update_schema.R
```

**Specify version manually:**
```bash
Rscript inst/scripts/update_schema.R 2.0.0
```

**From R console:**
```r
source("inst/scripts/update_schema.R")
```

### 3. Verify Changes

Check the generated files:
- `inst/schema/cmd_schema.yaml`
- `inst/schema/cmd_schema.linkml.yaml`

### 4. Commit to Git

```bash
git add inst/schema/cmd_data_dictionary.csv
git add inst/schema/cmd_schema.yaml
git add inst/schema/cmd_schema.linkml.yaml
git add inst/schema/archive/
git commit -m "Update schema to version X.Y.Z"
```

---

## Schema Versioning

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version (X.0.0): Breaking changes
  - Removing fields
  - Changing field types (e.g., character → integer)
  - Changing field semantics
  
- **MINOR** version (X.Y.0): Backward-compatible additions
  - Adding new optional fields
  - Adding new enum values
  - Expanding allowed values
  
- **PATCH** version (X.Y.Z): Backward-compatible fixes
  - Fixing typos in descriptions
  - Correcting validation patterns
  - Updating documentation

---

## Manual Schema Generation

If you need more control, generate schemas manually:

```r
library(yaml)
source("R/loadSchema.R")

# Load data dictionary
dict <- read.csv("inst/schema/cmd_data_dictionary.csv", stringsAsFactors = FALSE)

# Generate YAML schema
table_to_yaml_schema(
  dict,
  schema_version = "1.2.0",
  schema_name = "curatedMetagenomicData_metadata_schema",
  schema_description = "Metadata schema for curatedMetagenomicData package",
  output_file = "inst/schema/cmd_schema.yaml"
)

# Generate LinkML schema
table_to_linkml_schema(
  dict,
  schema_id = "https://github.com/waldronlab/curatedMetagenomicData",
  schema_version = "1.2.0",
  output_file = "inst/schema/cmd_schema.linkml.yaml"
)
```

---

## Data Dictionary Format

The `cmd_data_dictionary.csv` file supports these columns:

### Required Columns
- **`col.name`** - Field name (used as key in YAML)
- **`col.class`** - Data type: character, integer, numeric, double
- **`unique`** - "unique" or "non-unique"
- **`required`** - "required" or "optional"
- **`multiplevalues`** - TRUE or FALSE (for list-valued fields)
- **`description`** - Human-readable description

### Optional Columns
- **`allowedvalues`** - Pipe-separated values (e.g., "Yes|No") or regex pattern
- **`dynamic.enum`** - Ontology root terms (e.g., "NCIT:C7057;EFO:0000408")
- **`dynamic.enum.property`** - Relationship property (e.g., "descendant", "children")
- **`delimiter`** - Delimiter for multiple values (e.g., ";", ",")
- **`static.enum`** - Static enum definitions
- **`corpus.type`** - Field category/type

### Example Rows

```csv
# Simple binary field
antibiotics_current_use,character,non-unique,optional,FALSE,"Antibiotics usage","Yes|No",NA,NA,NA,NA,NA,binary

# Dynamic enum with ontology
disease,character,non-unique,optional,TRUE,"Reported disease type(s)",NA,NA,"NCIT:C7057;EFO:0000408","descendant",";",NA,dynamic_enum

# Regex pattern field
sample_id,character,unique,required,FALSE,"Sample identifier.","[0-9a-zA-Z]\S+",NA,NA,NA,NA,NA,regexp
```

---

## Schema Validation

### Validate LinkML Schema

```bash
# Check schema is valid
python3 -c "
from linkml_runtime import SchemaView
schema = SchemaView('inst/schema/cmd_schema.linkml.yaml')
print('✓ Schema is valid')
print(f'  Slots: {len(schema.all_slots())}')
print(f'  Enums: {len(schema.all_enums())}')
"
```

### Validate Data Against Schema

```r
# Load schema
schema <- load_metadata_schema("inst/schema/cmd_schema.yaml")

# Validate data
result <- validate_data_against_schema(your_data, schema)

# Check results
if (!result$valid) {
  cat("Errors:\n")
  for (err in result$errors) cat("  -", err, "\n")
}
if (length(result$warnings) > 0) {
  cat("Warnings:\n")
  for (warn in result$warnings) cat("  -", warn, "\n")
}
```

### Combined Field Validation

The schema supports combined field validation for paired fields that must be validated together. For example, `feces_phenotype` and `feces_phenotype_value` are validated as pairs:

```r
# Valid paired data
data <- data.frame(
  feces_phenotype = "Bristol stool form score (observable entity)<;>Calprotectin Measurement",
  feces_phenotype_value = "3<;>150.5",
  stringsAsFactors = FALSE
)

result <- validate_data_against_schema(data, schema)
# This will pass validation

# Invalid paired data - count mismatch
data_invalid <- data.frame(
  feces_phenotype = "Bristol stool form score (observable entity)<;>Calprotectin Measurement",
  feces_phenotype_value = "3",  # Only 1 value for 2 phenotypes
  stringsAsFactors = FALSE
)

result <- validate_data_against_schema(data_invalid, schema)
# This will show warning about count mismatch
```

**Combined validation checks:**
- Both fields must have equal number of values when split by delimiter
- Each phenotype value must be from the allowed enum
- Each measurement value must match the expected pattern
- If one field has a value, the other must also have a value
- Combined format: `phenotype1:value1<;>phenotype2:value2`

---

## Workflow Best Practices

### For Development
1. Work on a feature branch
2. Update `cmd_data_dictionary.csv`
3. Run update script
4. Test with sample data
5. Create pull request

### For Release
1. Decide on version number (following semver)
2. Update schema with new version
3. Review all changes in generated files
4. Update package DESCRIPTION version
5. Tag release in git

### Keeping Track of Changes
The `archive/` directory automatically stores versioned snapshots:
```
archive/
  cmd_schema_v1.0.0.yaml
  cmd_schema_v1.0.0.linkml.yaml
  cmd_schema_v1.1.0.yaml
  cmd_schema_v1.1.0.linkml.yaml
```

Use `git diff` to compare versions:
```bash
git diff archive/cmd_schema_v1.0.0.yaml archive/cmd_schema_v1.1.0.yaml
```

---

## Schema Metadata

Each generated schema includes metadata:

### YAML Schema
```yaml
schema_info:
  name: curatedMetagenomicData_metadata_schema
  version: "1.0.0"
  description: "Metadata schema for curatedMetagenomicData package"
  last_updated: "2026-01-23"
```

### LinkML Schema
```yaml
id: https://github.com/waldronlab/curatedMetagenomicData
name: curatedMetagenomicData
version: "1.0.0"
description: "Metadata schema for curatedMetagenomicData package"
```

The `last_updated` field is automatically set to the current date when running the update script.

---

## Troubleshooting

### Schema validation fails
- Check for syntax errors in `cmd_data_dictionary.csv`
- Ensure all required columns are present
- Verify regex patterns are valid
- Check ontology term formats (e.g., "NCIT:C7057")

### Fields not generating correctly
- Check for typos in column names
- Ensure data types are valid (character, integer, numeric, double)
- Verify enum values don't contain special characters

### Version conflicts
- Always increment version when making changes
- Use the update script to avoid manual versioning errors
- Check `schema_info` section in generated YAML

---

## Additional Resources

- [LinkML Documentation](https://linkml.io/)
- [Semantic Versioning](https://semver.org/)
- [YAML Specification](https://yaml.org/spec/)
- Package vignettes: `vignette("manage_schema")`

---

## Questions?

For questions or issues related to schema maintenance, please open an issue on the project repository.
