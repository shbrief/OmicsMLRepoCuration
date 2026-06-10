# OmicsMLRepoCuration

This package supports metadata harmonization and curation processes for omics
data AI/ML applications. It focuses on incorporating controlled language
(ontology) and supporting comparable analysis across datasets.

## Installation

Install from GitHub:

```r
if (!require("devtools")) install.packages("devtools")
devtools::install_github("shbrief/OmicsMLRepoCuration")
```

## Key Features

- **Schema management**: Load, validate, and export metadata schemas in YAML
  and LinkML formats
- **Ontology mapping**: Map metadata terms to controlled ontology vocabularies
- **Data validation**: Validate curated data against schema definitions
- **Curation statistics**: Check completeness and coverage of curated metadata

## Quick Start

```r
library(OmicsMLRepoCuration)

# Load a metadata schema
schema_file <- system.file("schema", "cmd_data_dictionary.yaml",
                           package = "OmicsMLRepoCuration")
schema <- loadMetadataSchema(schema_file)

# Extract ontology prefixes from term IDs
terms <- c("HP:0001824", "MONDO:0010200", "NCIT:C122328")
getOntologies(terms)
```

## Vignettes

- Choosing Dynamic Enum Nodes
- Managing metadata schema
- Schema Validation
- Data Validation Against Schema

## License

GPL-3
