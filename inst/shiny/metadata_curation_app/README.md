# Metadata Curation and Validation Shiny App

An interactive Shiny application for curating and validating metadata against the OmicsMLRepoCuration schema.

## Features

### 📤 Data Upload
- Load CSV/TSV files
- Create new datasets from templates
- Support for various delimiters (comma, tab, semicolon)
- Preview uploaded data

### ✏️ Data Editor
- Interactive editable data table
- Add/delete rows
- Add columns from schema or custom
- Inline cell editing
- Download curated data as CSV
- Required fields highlighted in yellow

### ✅ Validation
- Real-time validation against schema
- Checks for:
  - Required fields
  - Data types
  - Pattern matching
  - Static enums (controlled vocabularies)
  - Dynamic enums (ontology-based)
- Detailed error and warning messages
- Field-by-field validation summary
- Visual status indicators

### 📚 Schema Browser
- Browse all schema fields
- View field definitions and requirements
- Check validation rules
- Explore dynamic enum configurations
- Filter and search fields
- Identify static vs dynamic enums

### ❓ Help
- Getting started guide
- List of required fields
- Dynamic enum explanations
- Validation tips

## Installation

### Prerequisites

Install required R packages:

```r
install.packages(c("shiny", "shinydashboard", "DT", "yaml", "dplyr", "readr", "jsonlite"))
```

### Running the App

#### From R Console

```r
library(shiny)

# Option 1: Run from package installation
runApp(system.file("shiny/metadata_curation_app", package = "OmicsMLRepoCuration"))

# Option 2: Run from source directory
runApp("inst/shiny/metadata_curation_app")
```

#### From Command Line

```bash
R -e "shiny::runApp('inst/shiny/metadata_curation_app')"
```

#### Deploy to shinyapps.io

```r
library(rsconnect)

# Configure your account first (one time)
# rsconnect::setAccountInfo(name='<ACCOUNT>', token='<TOKEN>', secret='<SECRET>')

# Deploy
rsconnect::deployApp(
  appDir = system.file("shiny/metadata_curation_app", package = "OmicsMLRepoCuration"),
  appName = "omics-metadata-curation"
)
```

## Usage Workflow

### 1. Upload or Create Data

**Upload existing data:**
1. Go to "Data Upload" tab
2. Click "Choose CSV or TSV File"
3. Select your metadata file
4. Adjust delimiter and header options
5. Click "Load Data"

**Create new template:**
1. Go to "Data Upload" tab
2. Specify number of rows
3. Click "Create Template"

### 2. Edit Metadata

1. Navigate to "Data Editor" tab
2. Click on cells to edit values inline
3. Use "Add Row" to insert new records
4. Select rows and click "Delete Selected Row(s)" to remove
5. Use "Add Column" to add fields from schema or custom columns
6. Required fields are highlighted in **yellow**

### 3. Validate Data

1. Go to "Validation" tab
2. Click "Run Validation"
3. Review results:
   - **Green status**: Validation passed
   - **Red status**: Critical errors found
   - **Yellow warnings**: Non-critical issues
4. Check detailed error/warning messages
5. Review field-by-field report
6. Return to Editor to fix issues

### 4. Browse Schema

1. Navigate to "Schema Browser" tab
2. Select a field from the dropdown
3. View field details including:
   - Data type and requirements
   - Validation rules
   - Allowed values (static enums)
   - Ontology configuration (dynamic enums)
4. Use "All Fields Summary" table to browse all fields at once

### 5. Download Curated Data

1. After validation passes, go to "Data Editor"
2. Click "Download Data"
3. Save the CSV file

## Understanding Dynamic Enums

Dynamic enums use ontology hierarchies to define allowed values:

### Example: Ancestry Fields

**ancestry (children)**
- Root: `HANCESTRO:0004` (Human ancestry categories)
- Property: `children` (direct children only)
- Allowed values: Direct child terms like `HANCESTRO:0005` (European), `HANCESTRO:0008` (Asian)

**ancestry_details (descendants)**
- Root: `HANCESTRO:0004`
- Property: `descendant` (all descendants)
- Allowed values: Any descendant term like `HANCESTRO:0015` (Japanese), `HANCESTRO:0568` (Irish)

### How to Use Dynamic Enums

1. Check the Schema Browser for the field's ontology roots
2. Use ontology browsers (e.g., OLS, BioPortal) to find appropriate term IDs
3. Enter term IDs in the format: `ONTOLOGY:ID` (e.g., `HANCESTRO:0015`)
4. For multivalued fields, separate with the specified delimiter (usually `;`)

Example for ancestry_details:
```
HANCESTRO:0568;HANCESTRO:0577
```

## Field Color Coding

- **Yellow background**: Required fields
- **Green in validation**: Pass
- **Red in validation**: Fail
- **Yellow in validation**: Warning

## Tips and Best Practices

### Data Entry
- Fill required fields first (highlighted in yellow)
- Use exact term IDs for ontology fields (e.g., `HANCESTRO:0005`)
- Check field descriptions in Schema Browser before entering data
- Follow the specified patterns (e.g., date formats, ID formats)

### Validation
- Run validation frequently as you edit
- Fix all **errors** before submission
- Review **warnings** - they may indicate data quality issues
- Use the field-by-field report to track completion

### Dynamic Enum Fields
- Look up ontology terms using:
  - [OLS (Ontology Lookup Service)](https://www.ebi.ac.uk/ols/)
  - [BioPortal](https://bioportal.bioontology.org/)
- Use the most specific term available
- For multivalued fields, separate terms with semicolon (`;`)

### Debugging
- Check "Quick Stats" in sidebar for overview
- Missing required fields will appear in validation errors
- Type mismatches appear as warnings
- Pattern violations indicate formatting issues

## Troubleshooting

### Data not loading
- Check file format (CSV or TSV)
- Verify correct delimiter selection
- Ensure file has proper encoding (UTF-8)

### Validation errors
- Review error messages for specific issues
- Check Schema Browser for field requirements
- Verify required fields are present and populated
- Check data types match schema expectations

### Performance issues
- Large files (>10,000 rows) may be slow
- Consider validating in batches
- Close other browser tabs
- Increase R memory if needed

## Support

For issues, questions, or contributions:
- GitHub Issues: [OmicsMLRepoCuration repository]
- Documentation: See package vignettes
- Schema docs: `inst/schema/README.md`

## Advanced Usage

### Custom Schema

To use a different schema:

1. Edit `app.R` and change the schema file path:
```r
schema_file <- "path/to/your/schema.yaml"
schema <- load_metadata_schema(schema_file)
```

2. Restart the app

### Extending the App

The app can be extended with:
- Custom validation functions
- Ontology term lookup integration
- Batch import/export
- History tracking
- Multi-user support
- Database integration

## Version History

- **1.0.0** (2026-01-24): Initial release
  - Data upload and editing
  - Schema-based validation
  - Dynamic enum support
  - Interactive schema browser
