# Data Schema Documentation

## Overview

The OmicsMLRepoCuration package uses a schema-based validation system to ensure metadata quality and consistency. The schema is defined in CSV format ([cmd_data_dictionary.csv](inst/schema/cmd_data_dictionary.csv)) and converted to YAML format for programmatic use.

## Schema File Locations

- **CSV Source**: `inst/schema/cmd_data_dictionary.csv` - Human-readable format
- **YAML Schema**: `inst/schema/cmd_data_dictionary.yaml` - Used by validation functions
- **LinkML Schema**: `inst/schema/cmd_data_dictionary_linkml.yaml` - LinkML-compatible format

## Schema Structure

Each field in the schema is defined with the following properties:

### Core Properties

| Property | Description | Example Values |
|----------|-------------|----------------|
| `col.name` | Field/column name | `age`, `body_site`, `fmt_role` |
| `col.class` | Data type | `character`, `integer`, `numeric`, `double` |
| `unique` | Uniqueness constraint | `unique`, `non-unique` |
| `required` | Whether field is required | `required`, `optional` |
| `multiplevalues` | Can contain multiple values | `TRUE`, `FALSE` |
| `description` | Human-readable description | "Age of the subject at sample collection" |

### Validation Properties

| Property | Description | Example Values |
|----------|-------------|----------------|
| `allowedvalues` | Allowed values or pattern | `Yes\|No`, `Adult\|Child\|Infant`, `[a-zA-Z-]+_[0-9]{4}` |
| `corpus.type` | Type of validation to apply | `static_enum`, `custom_enum`, `binary`, `regexp`, `dynamic_enum` |
| `static.enum` | Static enumeration values (pipe-separated) | `Yes\|No`, `Adult\|Child\|Infant` |
| `dynamic.enum` | Ontology roots for dynamic enums | `NCIT:C16423;UBERON:0001062` |
| `dynamic.enum.property` | Property/relationship for dynamic enum expansion | `descendants`, `subClassOf` |
| `delimiter` | Separator for multiple values | `;`, `\|`, `<;>` |
| `separator` | Alternative name for delimiter (deprecated) | `;`, `\|` |
| `ontology` | Ontology term IDs | `NCIT:C25150\|NCIT:C16423` |

## Understanding `corpus.type`

The `corpus.type` field determines how `allowedvalues` is interpreted:

### 1. `static_enum` - Fixed List of Values

Pipe-separated list of exact values that are allowed.

**Example:**
```csv
col.name: age_group
corpus.type: static_enum
allowedvalues: Newborn|Infant|Child|Adolescent|Adult|Elderly
multiplevalues: FALSE
```

**Validation:** Exact string matching using `%in%` operator
- ✓ Valid: `"Adult"`, `"Child"`
- ✗ Invalid: `"adult"` (case-sensitive), `"Teenager"`

### 2. `custom_enum` - Custom Enumeration

Similar to `static_enum` but for application-specific controlled vocabularies. Values may contain special characters.

**Example:**
```csv
col.name: fmt_role
corpus.type: custom_enum
allowedvalues: Recipient (after procedure)|Recipient (before procedure)|Donor
multiplevalues: FALSE
```

**Validation:** Exact string matching
- ✓ Valid: `"Donor"`, `"Recipient (after procedure)"`
- ✗ Invalid: `"Recipient"`, `"Donor (healthy)"`

### 3. `binary` - Yes/No Values

Two-value fields, typically Yes/No.

**Example:**
```csv
col.name: westernized
corpus.type: binary
allowedvalues: Yes|No
multiplevalues: FALSE
```

**Validation:** Exact matching to `"Yes"` or `"No"`
- ✓ Valid: `"Yes"`, `"No"`, `NA`
- ✗ Invalid: `"yes"`, `"TRUE"`, `"1"`

### 4. `regexp` - Regular Expression Pattern

The entire `allowedvalues` string is treated as a regular expression pattern. The `|` character represents alternation (OR) in regex.

**Example:**
```csv
col.name: study_name
corpus.type: regexp
allowedvalues: [a-zA-Z-]+_[0-9]{4}|[a-zA-Z-]+_[0-9]{4}[a-zA-Z-]+
multiplevalues: FALSE
```

**Validation:** Pattern matching using `grepl()`
- ✓ Valid: `"SmithA_2020"`, `"JonesB_2021abc"`
- ✗ Invalid: `"Study2020"`, `"Smith_20"`

### 5. `dynamic_enum` - Ontology-Based Enumeration

Values come from ontology terms, allowing flexible expansion.

**Example:**
```csv
col.name: disease
corpus.type: dynamic_enum
dynamic.enum: MONDO:0000001;DOID:4
multiplevalues: TRUE
delimiter: ;
```

**Validation:** Values checked against ontology terms and descendants

### 6. Other Types

- `any` - No validation on values
- `character` - Any character string
- `integer` - Integer values
- `numeric` - Numeric values

## Multiple Values

Fields with `multiplevalues = TRUE` can contain multiple entries separated by a delimiter.

**Example:**
```csv
col.name: smoker
corpus.type: static_enum
allowedvalues: Smoker (finding)|Non-smoker (finding)|Ex-smoker (finding)|Never smoked tobacco (finding)
multiplevalues: TRUE
delimiter: ;
```

**Valid data:**
- Single value: `"Smoker (finding)"`
- Multiple values: `"Non-smoker (finding);Ex-smoker (finding)"`
- NA: `NA`

**Validation:** Each value after splitting by delimiter is checked against allowed values.

## Common Field Examples

### Example 1: Simple Enum Field

```csv
col.name: body_site
col.class: character
unique: non-unique
required: optional
multiplevalues: FALSE
description: Body site where sample was collected
allowedvalues: feces|oral cavity|skin epidermis|vagina|nasal cavity|milk
corpus.type: static_enum
```

**YAML representation:**
```yaml
body_site:
  col_name: body_site
  col_class: character
  uniqueness: non-unique
  required: no
  multiple_values: no
  description: Body site where sample was collected
  validation:
    allowed_values:
      - feces
      - oral cavity
      - skin epidermis
      - vagina
      - nasal cavity
      - milk
```

### Example 2: Multi-Value Enum Field

```csv
col.name: feces_phenotype
col.class: character
unique: non-unique
required: optional
multiplevalues: TRUE
delimiter: ;
allowedvalues: Bristol stool form score (observable entity)|Calprotectin Measurement|Harvey-Bradshaw Index Clinical Classification
corpus.type: static_enum
```

**Usage in data:**
```r
# Valid values
"Bristol stool form score (observable entity)"
"Calprotectin Measurement;Harvey-Bradshaw Index Clinical Classification"
NA

# Invalid values
"Bristol Score"  # Not in allowed values
"Bristol stool form score (observable entity)|Calprotectin Measurement"  # Wrong delimiter (| instead of ;)
```

### Example 3: Regex Pattern Field

```csv
col.name: sample_id
col.class: character
unique: unique
required: required
multiplevalues: FALSE
allowedvalues: ^[A-Za-z0-9_-]+$
corpus.type: regexp
```

**Usage:**
```r
# Valid
"Sample_001"
"SAMPLE-ABC-123"

# Invalid
"Sample 001"  # Contains space
"Sample#001"  # Contains invalid character #
```

## Using the Schema

### Loading the Schema

```r
library(OmicsMLRepoCuration)

# Load schema from package
schema_file <- system.file("schema", "cmd_data_dictionary.yaml", 
                          package = "OmicsMLRepoCuration")
schema <- load_metadata_schema(schema_file)

# Or load from file path
schema <- load_metadata_schema("inst/schema/cmd_data_dictionary.yaml")
```

### Validating Data

```r
# Load your data
data <- read.csv("my_sample_data.tsv", sep = "\t")

# Validate against schema
result <- validate_data_against_schema(data, schema)

# Check results
if (result$valid) {
  cat("✓ Data is valid\n")
} else {
  cat("✗ Validation failed\n")
  
  # Show errors
  if (length(result$errors) > 0) {
    cat("\nErrors:\n")
    for (err in result$errors) {
      cat("  -", err, "\n")
    }
  }
  
  # Show warnings
  if (length(result$warnings) > 0) {
    cat("\nWarnings:\n")
    for (warn in result$warnings) {
      cat("  -", warn, "\n")
    }
  }
}
```

### Querying Schema Information

```r
# Get all required fields
required_fields <- get_required_fields(schema)

# Get field definition
field_def <- get_field_definition(schema, "age")

# Get fields by category
disease_fields <- get_fields_by_category(schema, "disease")

# Get all categories
categories <- get_all_categories(schema)
```

### Creating a Template

```r
# Generate empty data frame with correct structure
template <- schema_to_template_df(schema, "sample_id")
```

## Validation Rules

### Type Checking

Data types are validated according to `col.class`:
- `character`: Any string value
- `integer`: Whole numbers (R also accepts numeric)
- `numeric`/`double`: Decimal numbers

### Required Fields

Fields with `required = "required"` or `required = TRUE` must be present in the data.

**Validation Error Example:**
```
Missing required fields: sample_id, sequencing_platform
```

### Value Validation

Based on `corpus.type`:

1. **Enum types** (`static_enum`, `custom_enum`, `binary`):
   - Single value fields: Value must exactly match one of the allowed values
   - Multi-value fields: After splitting by delimiter, each value must match

2. **Regex patterns** (`regexp`):
   - Value must match the regular expression pattern

3. **Dynamic enums** (`dynamic_enum`):
   - Value must be a valid ontology term or descendant of specified roots

### NA Handling

- `NA` values are allowed for non-required fields
- `NA` values skip validation checks
- Empty strings `""` are treated differently from `NA`

## Best Practices

### For Schema Maintainers

1. **Use appropriate corpus.type**: 
   - Use `static_enum` for fixed vocabularies
   - Use `regexp` for pattern-based validation
   - Use `custom_enum` for application-specific terms

2. **Be explicit with delimiters**:
   - Always specify delimiter when `multiplevalues = TRUE`
   - Use consistent delimiters across similar fields

3. **Document allowed values**:
   - Keep `allowedvalues` up to date
   - Use clear, unambiguous terms

4. **Test schema changes**:
   - Regenerate YAML after CSV changes
   - Validate existing data against new schema

### For Data Curators

1. **Check required fields**: Ensure all required fields are present

2. **Use exact values**: Enum values are case-sensitive and must match exactly

3. **Follow delimiter conventions**: Use the specified delimiter for multi-value fields

4. **Validate early**: Run validation frequently during curation

5. **Handle NA properly**: Use `NA` (not empty strings) for missing values

## Regenerating Schema

After modifying the CSV schema, regenerate the YAML files:

```r
library(OmicsMLRepoCuration)

# Load CSV
dict_csv <- read.csv("inst/schema/cmd_data_dictionary.csv")

# Generate YAML schema
table_to_yaml_schema(
  dict_csv,
  output_file = "inst/schema/cmd_data_dictionary.yaml"
)

# Generate LinkML schema (optional)
table_to_linkml_schema(
  dict_csv,
  output_file = "inst/schema/cmd_data_dictionary_linkml.yaml"
)

# Reinstall package to use new schema
devtools::install()
```

## Troubleshooting

### Common Validation Errors

**Error: "Missing required fields: X, Y, Z"**
- **Solution**: Add the missing columns to your data

**Warning: "Field 'X' has N values not matching pattern: ..."**
- **Cause**: Field has `corpus.type = regexp` and values don't match the pattern
- **Solution**: Check your values against the regex pattern in `allowedvalues`

**Warning: "Field 'X' has N invalid values: A, B. Allowed values: C, D, E"**
- **Cause**: Field has enum type and values aren't in the allowed list
- **Solution**: Use exact values from `allowedvalues`, check capitalization and spelling

**Warning: "Field 'X' expected type 'Y' but found 'Z'"**
- **Cause**: Data type mismatch (e.g., character instead of numeric)
- **Solution**: Convert the column to the correct type before validation

### Getting Help

1. **Check the schema**: View field definitions in `cmd_data_dictionary.csv`
2. **Use query functions**: `get_field_definition()`, `get_required_fields()`
3. **Check examples**: See test files in the package repository
4. **Read validation messages carefully**: They indicate exactly what's wrong

## See Also

- [CORPUS_TYPE_FIX_SUMMARY.md](CORPUS_TYPE_FIX_SUMMARY.md) - Technical details on schema parsing
- [inst/schema/README.md](inst/schema/README.md) - Schema maintenance guide
- Package vignettes: `vignette("validation", package = "OmicsMLRepoCuration")`
