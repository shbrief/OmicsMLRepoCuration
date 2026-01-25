# Quick Start Guide: Metadata Curation Shiny App

## Installation

1. **Install the package** (if not already installed):
```r
# Install from GitHub or local source
devtools::install("~/OmicsMLRepo/OmicsMLRepoCuration")
```

2. **Install required Shiny packages**:
```r
install.packages(c("shiny", "shinydashboard", "DT", "yaml", "dplyr", "readr", "jsonlite"))
```

## Launching the App

### Quick Launch
```r
library(OmicsMLRepoCuration)
launch_curation_app()
```

### Custom Options
```r
# Launch in RStudio viewer pane
launch_curation_app(launch.browser = FALSE)

# Launch on specific port
launch_curation_app(port = 3838)

# Launch on network-accessible address
launch_curation_app(host = "0.0.0.0", port = 8080)
```

## 5-Minute Workflow

### 1. Start with a Template (30 seconds)
1. Launch the app
2. Go to **Data Upload** tab
3. Enter number of rows (e.g., 10)
4. Click **Create Template**
5. App automatically navigates to Editor

### 2. Enter Your Data (2 minutes)
1. In **Data Editor** tab:
   - Click cells to edit (required fields are yellow)
   - Fill in required fields: `sample_id`, `subject_id`, `body_site`, `country`, `sex`, `control`, `ancestry`, `ancestry_details`
2. Add optional columns:
   - Click **Add Column**
   - Select from schema dropdown (e.g., `age`, `disease`)
   - Click **Add**

### 3. Validate (1 minute)
1. Go to **Validation** tab
2. Click **Run Validation**
3. Check status boxes:
   - Green = Pass ✓
   - Red = Errors to fix ✗
4. Read error/warning messages
5. Return to Editor to fix issues

### 4. Review Schema (30 seconds)
1. Go to **Schema Browser** tab
2. Select a field (e.g., `ancestry`)
3. View:
   - Field description
   - Allowed values or patterns
   - Ontology roots (for dynamic enums)

### 5. Download (30 seconds)
1. Return to **Data Editor**
2. Click **Download Data**
3. Save as CSV

## Example: Curating Sample Data

### Step-by-Step Example

**Create template with 3 rows:**
```r
launch_curation_app()
# In browser: Data Upload → Set "3" rows → Create Template
```

**Fill in required data:**

| sample_id | subject_id | body_site | country | sex | control | ancestry | ancestry_details |
|-----------|------------|-----------|---------|-----|---------|----------|------------------|
| SAMPLE001 | SUB001 | stool | USA | female | case | HANCESTRO:0005 | HANCESTRO:0568 |
| SAMPLE002 | SUB002 | skin | CAN | male | control | HANCESTRO:0008 | HANCESTRO:0015 |
| SAMPLE003 | SUB003 | stool | GBR | female | case | HANCESTRO:0005 | HANCESTRO:0304 |

**Add optional columns:**
- Add `age` column → Enter: 25, 34, 28
- Add `age_unit` column → Enter: Year, Year, Year
- Add `age_group` column → Enter: Adult, Adult, Adult

**Validate:**
- Go to Validation tab → Run Validation
- Should show: ✓ Status: PASSED, 0 Errors, 0 Warnings

**Download:**
- Data Editor → Download Data → Save `curated_metadata_2026-01-24.csv`

## Common Fields & Examples

### Required Fields
```
sample_id:         SAMPLE001, SAMPLE002, ...
subject_id:        SUB001, SUB002, ...
body_site:         stool, skin, oral cavity
country:           USA, CAN, GBR, JPN, ...
sex:               female, male
control:           case, control
ancestry:          HANCESTRO:0005, HANCESTRO:0008
ancestry_details:  HANCESTRO:0568, HANCESTRO:0015
```

### Common Optional Fields
```
age:               25, 34, 28 (integers)
age_unit:          Year, Month, Day
age_group:         Adult, Child, Elderly
disease:           NCIT:C2926, NCIT:C2952
treatment:         antibiotics, chemotherapy
smoker:            Yes, No
```

### Dynamic Enum Examples

**Ancestry (HANCESTRO)**
```
HANCESTRO:0005  → European ancestry
HANCESTRO:0008  → Asian ancestry
HANCESTRO:0014  → African American ancestry
HANCESTRO:0015  → Japanese ancestry
HANCESTRO:0568  → Irish ancestry
```

Look up terms at: https://www.ebi.ac.uk/ols/ontologies/hancestro

**Multiple Values**
For `ancestry_details` (multivalued field):
```
HANCESTRO:0568;HANCESTRO:0577;HANCESTRO:0581
```
Separate with semicolon (`;`)

## Tips & Tricks

### Efficient Data Entry
- **Tab** to move between cells
- **Enter** to go to next row
- Copy-paste from Excel works!
- Required fields highlighted in yellow

### Finding Ontology Terms
1. Go to Schema Browser
2. Select field (e.g., `ancestry`)
3. Note the ontology root (e.g., `HANCESTRO:0004`)
4. Visit [OLS](https://www.ebi.ac.uk/ols/)
5. Search for appropriate terms
6. Copy term ID (e.g., `HANCESTRO:0015`)

### Validation Strategy
1. Fill required fields first
2. Validate early and often
3. Fix errors before warnings
4. Use field-by-field report to track progress
5. Check "Quick Stats" in sidebar

### Working with Large Datasets
- Upload existing CSV rather than entering manually
- Validate incrementally (validate → fix → repeat)
- Download frequently to save progress
- For very large files, consider batch processing

## Troubleshooting

### "Data not loaded"
- Check file format (CSV or TSV)
- Verify delimiter matches file
- Try different delimiter option

### "Missing required fields" error
Check these fields exist and are filled:
- sample_id, subject_id, body_site, country
- sex, control, ancestry, ancestry_details

### "Type mismatch" warning
- `age` should be numbers (25, not "twenty-five")
- Dates should follow pattern if specified
- Check Schema Browser for expected type

### Validation doesn't run
- Make sure data is loaded
- Check browser console for errors
- Try refreshing the app

### App won't launch
```r
# Check if packages are installed
required <- c("shiny", "shinydashboard", "DT", "yaml", "dplyr", "readr", "jsonlite")
missing <- required[!sapply(required, requireNamespace, quietly = TRUE)]
if (length(missing) > 0) {
  install.packages(missing)
}
```

## Advanced Features

### Upload Existing Metadata
1. Data Upload tab
2. Click "Choose CSV or TSV File"
3. Select file
4. Adjust delimiter if needed
5. Click "Load Data"

### Field-by-Field Report
- Validation tab → Expand "Field-by-Field Report"
- Shows completion percentage for each field
- Color-coded by status (Required/Optional/Not in schema)
- Progress bars show fill rate

### Schema Summary Table
- Schema Browser → Expand "All Fields Summary"
- Searchable/filterable table of all fields
- Filter by validation type or requirement status
- Quick reference for all schema fields

## Next Steps

### Learn More
- See full documentation: `inst/shiny/metadata_curation_app/README.md`
- Read LinkML validation vignette: `vignettes/linkml_validation.rmd`
- Check schema README: `inst/schema/README.md`

### Production Use
- Deploy to shinyapps.io for team access
- Integrate with database for persistence
- Add custom validation rules
- Connect to ontology lookup APIs

### Get Help
- GitHub Issues: Report bugs or request features
- Package vignettes: In-depth guides
- Schema documentation: Field definitions

---

**Happy Curating! 🎉**
