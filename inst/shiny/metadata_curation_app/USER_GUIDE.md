# Omics Metadata Manager - Complete User Guide

**Version**: 0.1.2  
**Last Updated**: January 25, 2026

---

## Table of Contents

1. [Getting Started](#getting-started)
2. [Dashboard Overview](#dashboard-overview)
3. [Import Data](#import-data)
4. [Data Editor](#data-editor)
5. [Data Curation (Detailed Guide)](#data-curation-detailed-guide)
6. [Quality Control](#quality-control)
7. [Ontology Browser](#ontology-browser)
8. [Export](#export)
9. [Complete Workflow Example](#complete-workflow-example)
10. [Troubleshooting](#troubleshooting)

---

## Getting Started

### Launching the App

```r
# Install the package (if not already installed)
devtools::install()

# Load and launch
library(OmicsMLRepoCuration)
launch_curation_app()
```

The app will open in your default web browser at `http://127.0.0.1:5616`.

### First Time Users

If this is your first time using the app:
1. Start by clicking **"Import Data"** in the sidebar
2. Click **"Load Demo Data"** to explore with sample data
3. Navigate through each tab to familiarize yourself with the interface

---

## Dashboard Overview

The **Dashboard** tab shows your project's current status:

### Value Boxes (Top Row)
- **Total Samples**: Number of rows in your dataset
- **Metadata Fields**: Number of columns
- **Completeness**: Overall percentage of filled cells
- **Quality Status**: Validation status (Not Assessed/Passed/Issues Found)

### Visualization Charts
- **Completeness by Field**: Bar chart showing which fields are most/least complete
- **Validation Status**: Summary of errors, warnings, and passed validation

### Quick Actions
Buttons to quickly navigate to key functions:
- **Import Data**: Load or create new data
- **Edit Data**: Open the data editor
- **Validate**: Run quality control checks
- **Export**: Download your curated data

---

## Import Data

### Option 1: Upload Your Own File

1. Click **"Choose CSV, TSV, or Excel File"**
2. Select your file from your computer
3. Configure file settings:
   - **File has header row**: Check if first row contains column names (usually checked)
   - **Separator**: Select delimiter (Comma for CSV, Tab for TSV)
4. Click **"Import Data"**

**Supported formats**: CSV, TSV, TXT, XLSX, XLS

### Option 2: Create from Template

If you're starting from scratch:

1. Set **"Number of samples"**: How many rows you need (e.g., 10, 50, 100)
2. Choose **"Template type"**:
   - **Minimal**: Only required fields (sample_id, study_id, etc.)
   - **Standard**: Common fields included
3. Click **"Create from Template"**

### Option 3: Load Demo Data

For testing and learning:
- Click **"Load Demo Data"** to load 10 sample records
- This data is already validated and ready to explore

### After Import

Once data is loaded, you'll see:
- A preview table showing the first 100 rows
- Summary showing number of samples and fields
- Count of required fields present

The app will automatically navigate to the **Dashboard** to show your data statistics.

---

## Data Editor

The **Data Editor** provides an interactive spreadsheet-like interface.

### Editing Cells

1. **Click any cell** to edit its value
2. Type your new value
3. **Press Enter** or click outside to save
4. Changes are saved immediately

### Toolbar Actions

**Add Sample** (+ icon):
- Adds a new empty row at the bottom
- Use this to add new samples to your dataset

**Delete Selected**:
1. Click on row numbers to select rows (multi-select supported)
2. Click "Delete Selected"
3. Confirm the deletion

**Duplicate Sample**:
1. Select a row by clicking its row number
2. Click "Duplicate Sample"
3. An exact copy is added at the bottom

**Add Field**:
1. Click "Add Field" button
2. In the box that appears, either:
   - Select a field from the schema dropdown, OR
   - Enter a custom field name
3. Click "Add Field" button to confirm
4. New column appears with empty values

**Quick Validate**:
- Runs validation and jumps to Quality Control tab
- Useful for quick checks as you edit

**Download**:
- Downloads current data as CSV
- Quick export without validation requirements

### Color Coding

- **Orange background**: Required fields (must be filled)
- **Red border**: Fields with validation errors
- **Yellow border**: Fields with warnings
- **Green border**: Valid, verified fields

### Tips

- Table is fully scrollable horizontally and vertically
- Use Page Length dropdown to show 10/25/50/100 rows at once
- Search box filters the entire table
- Sort by clicking column headers

---

## Data Curation (Detailed Guide)

The **Data Curation** tab is where you standardize and clean your metadata. This section requires careful reading as these are powerful tools.

---

### 🎯 Tool 1: Ontology Term Mapping

**What it does**: Converts human-readable text values into standardized ontology identifiers.

**Why you need it**: Ontologies provide controlled vocabularies that make data comparable across studies. Instead of having "European", "Euro", "Caucasian" as different values, you map them all to the standard term "HANCESTRO:0005" (European).

**When to use it**: 
- You have free-text values that should be standardized
- You need to convert descriptions to ontology IDs
- Your schema requires ontology terms but you have plain text

#### Step-by-Step Instructions

**STEP 1: Select Field to Map**
```
Example: You have a column called "ancestry" with values like:
- "European"
- "African American"  
- "East Asian"
- "Hispanic or Latino"
```

Click the dropdown under **"Select field to map"** and choose your field (e.g., "ancestry").

**STEP 2: Choose Target Ontology**

Select which ontology to use:

| Ontology | Best For | Example Terms |
|----------|----------|---------------|
| **HANCESTRO** | Ancestry, ethnicity, population groups | European, African, Asian |
| **NCIT** | Cancer types, diseases, general biomedical | Breast Cancer, Diabetes |
| **EFO** | Experimental factors, traits, phenotypes | Body mass index, Age |
| **HP** | Human phenotypes, clinical features | Seizures, Intellectual disability |
| **MONDO** | Diseases across all organisms | Alzheimer disease, COVID-19 |

For ancestry, choose **HANCESTRO**.

**STEP 3: Set Number of Suggestions**

- Default: **3** (recommended)
- Range: 1-10
- Higher numbers give more options but may include less relevant matches

**STEP 4: Run Mapping**

Click **"Map Values to Ontology Terms"** button.

⏳ Progress bar appears - this takes 10-30 seconds depending on:
- Number of unique values in your field
- Ontology size
- Internet connection speed (queries online databases)

**STEP 5: Review Results**

A table appears with these columns:

| Column | Description | Example |
|--------|-------------|---------|
| **OriginalValue** | Your input text | "European" |
| **SuggestedID** | Ontology identifier | "HANCESTRO:0005" |
| **SuggestedLabel** | Official term name | "European" |
| **Score** | Match confidence (0-1) | 0.95 |

**Understanding Scores**:
- **0.9 - 1.0**: Excellent match, likely exact
- **0.7 - 0.9**: Good match, review to confirm
- **0.5 - 0.7**: Partial match, verify carefully
- **< 0.5**: Poor match, may need manual curation

The Score column has a green bar - longer bar = better match.

**STEP 6: Select Mappings to Apply**

1. **Review each suggestion** - check if SuggestedLabel matches your intent
2. **Click rows to select** (you can select multiple rows):
   - Click once to select a single row (highlights in blue)
   - Hold Shift and click to select range
   - Hold Ctrl/Cmd and click for individual selections
3. **Only select mappings you trust** (usually Score > 0.7)

**STEP 7: Apply Mappings**

1. Click **"Apply Selected Mappings"** button
2. ✓ Notification appears: "Applied X mappings"
3. Your data is now updated - original values replaced with ontology IDs

**Example Transformation**:
```
BEFORE mapping:
ancestry: "European", "African American", "East Asian"

AFTER mapping:
ancestry: "HANCESTRO:0005", "HANCESTRO:0568", "HANCESTRO:0008"
```

**STEP 8: Clear Results (Optional)**

Click **"Clear Results"** to remove the mapping table and start over.

#### Practical Example: Ancestry Mapping

**Scenario**: You have 100 samples with ancestry entered as free text.

```r
# Your data looks like:
sample_id    ancestry
SAMPLE001    European
SAMPLE002    African American
SAMPLE003    european (lowercase)
SAMPLE004    East Asian
SAMPLE005    European
...
```

**Steps**:
1. Select field: **ancestry**
2. Target ontology: **HANCESTRO**
3. Suggestions: **3**
4. Click "Map Values to Ontology Terms"

**Results you might see**:

| OriginalValue | SuggestedID | SuggestedLabel | Score |
|---------------|-------------|----------------|-------|
| European | HANCESTRO:0005 | European | 1.00 |
| european | HANCESTRO:0005 | European | 1.00 |
| African American | HANCESTRO:0568 | African American | 0.98 |
| East Asian | HANCESTRO:0008 | East Asian | 0.95 |

5. **Select all rows** (all scores are high)
6. Click "Apply Selected Mappings"
7. All instances of "European" and "european" now map to "HANCESTRO:0005"

---

### 🔄 Tool 2: Cross-Ontology Mapping (OxO)

**What it does**: Converts ontology terms from one ontology to equivalent terms in a different ontology.

**Why you need it**: Different databases/studies use different ontologies. OxO finds equivalent terms across ontologies so you can convert between them.

**When to use it**:
- You have data with NCIT disease codes but need MONDO codes
- You want to convert EFO terms to HANCESTRO
- You're combining datasets that use different ontology standards

**Important**: This tool only works on fields that ALREADY contain ontology IDs in the format "PREFIX:ID" (e.g., "NCIT:C2855", "EFO:0000228").

#### Step-by-Step Instructions

**STEP 1: Prepare Your Data**

First, ensure your field contains valid ontology IDs:
```
✓ Valid format:
- "NCIT:C2855"
- "EFO:0000228"
- "HANCESTRO:0005"
- "HP:0003003"
- "MONDO:0010200"

✗ Invalid format:
- "Breast Cancer" (plain text - use Ontology Term Mapping first!)
- "C2855" (missing prefix)
- "ncit:c2855" (must be uppercase)
```

If you have plain text, you must **first use Ontology Term Mapping** to convert to IDs, then use OxO.

**STEP 2: Select Field with Ontology IDs**

Click dropdown under **"Select field with ontology IDs"** and choose your field.

Example: You might have:
- Field name: `disease_ontology`
- Values: "NCIT:C2855", "NCIT:C35025", "NCIT:C122328"

**STEP 3: Choose Target Ontology**

Where do you want to map TO?

| Target | Use When |
|--------|----------|
| **NCIT** | Converting to NCI Thesaurus (widely used) |
| **EFO** | Converting to Experimental Factor Ontology |
| **HP** | Converting to Human Phenotype Ontology |
| **MONDO** | Converting to MONDO Disease Ontology |
| **HANCESTRO** | Converting to ancestry terms |

**STEP 4: Set Mapping Distance**

This controls how "far" to search for mappings:

- **Distance 1 (direct)**: Only exact, direct mappings
  - Fastest
  - Most reliable
  - May find fewer mappings
  - **Recommended for most users**

- **Distance 2 (one hop)**: Includes indirect mappings through one intermediate ontology
  - Slower
  - More mappings found
  - Slightly less reliable
  - Use when distance 1 finds nothing

- **Distance 3 (two hops)**: Includes mappings through two intermediate ontologies
  - Slowest
  - Most mappings found
  - Least reliable
  - Use only if desperate

**Start with Distance 1**. Only increase if you get no results.

**STEP 5: Run OxO Mapping**

Click **"Map Across Ontologies"** button.

⏳ Progress bar - typically 5-15 seconds per unique term. Requires internet connection to EBI's OxO service.

**STEP 6: Review Results**

Table appears with these columns:

| Column | Description | Example |
|--------|-------------|---------|
| **SourceID** | Your original ontology ID | "NCIT:C2855" |
| **TargetID** | Equivalent ID in target ontology | "MONDO:0007254" |
| **TargetLabel** | Target term name | "breast cancer" |
| **Distance** | How far the mapping is (1/2/3) | 1 |

**Color Coding**:
- **Green (Distance 1)**: Direct mapping - most trustworthy
- **Yellow (Distance 2)**: One hop - generally reliable
- **Red (Distance 3)**: Two hops - verify carefully

**Interpreting "No mapping"**:
If you see "No mapping" for a term, it means:
- No equivalent exists in target ontology (the concept may be unique)
- The term is too specific/rare
- Try increasing distance or using a different target ontology

**STEP 7: Export or Use Results**

Unlike Ontology Term Mapping, OxO results are **for reference only** - they don't automatically update your data.

To use these mappings:
1. Review the TargetID values you want
2. Go back to **Data Editor** tab
3. Manually enter the TargetID values, OR
4. Create a new column and copy-paste target IDs

#### Practical Example: Disease Code Conversion

**Scenario**: You have cancer data with NCIT disease codes but need to submit to a database that requires MONDO codes.

```r
# Your data:
sample_id    disease_code
SAMPLE001    NCIT:C2855      # Breast Cancer
SAMPLE002    NCIT:C7541      # Colon Cancer
SAMPLE003    NCIT:C3224      # Melanoma
```

**Steps**:
1. Select field: **disease_code**
2. Target ontology: **MONDO**
3. Mapping distance: **1** (direct only)
4. Click "Map Across Ontologies"

**Results**:

| SourceID | TargetID | TargetLabel | Distance |
|----------|----------|-------------|----------|
| NCIT:C2855 | MONDO:0007254 | breast cancer | 1 |
| NCIT:C7541 | MONDO:0005575 | colon cancer | 1 |
| NCIT:C3224 | MONDO:0005105 | melanoma | 1 |

5. All mappings found with Distance 1 (green) ✓
6. Create new column "disease_mondo" in Data Editor
7. Enter corresponding MONDO IDs
8. Now you have both NCIT and MONDO codes!

#### When OxO Finds Nothing

If all results show "No mapping":

**Troubleshooting**:
1. ✓ **Check format**: Must be "PREFIX:ID" with uppercase
2. ✓ **Verify IDs are valid**: Try searching the ID on ontology websites
3. Try **increasing distance to 2**
4. Try **different target ontology**
5. Check **internet connection** (OxO needs API access)

Some terms simply don't have equivalents across all ontologies - this is normal!

---

### 📝 Tool 3: Bulk Operations

#### Find and Replace

**What it does**: Searches for text in a field and replaces all occurrences.

**When to use it**:
- Standardize inconsistent values: "Male"/"male"/"M" → "male"
- Fix typos: "Europan" → "European"
- Remove unwanted characters: "Sample-001" → "Sample001"

**Steps**:

1. **Select field**: Choose which column to search
2. **Find**: Enter text to search for (e.g., "Male")
3. **Replace with**: Enter replacement text (e.g., "male")
4. **Options**:
   - ☐ **Case sensitive**: Uncheck to match "Male", "MALE", "male" all together
   - ☐ **Match whole word only**: Check to avoid partial matches (e.g., won't match "Female")
5. Click **"Preview"**: Shows count of matches found
6. Review the count - is it what you expected?
7. Click **"Apply Changes"**: Executes replacement
8. ✓ Notification confirms completion

**Example**:
```
Find: "Eur"
Replace with: "European"
Case sensitive: unchecked
→ Changes: "Eur", "eur", "EUR" all become "European"
```

#### Fill Down

**What it does**: Fills empty cells with the value from the cell directly above.

**When to use it**:
- Study IDs are repeated for all samples from same study
- Grouped data where values apply to multiple rows
- Fill gaps in metadata after manual entry

**Steps**:

1. **Select field**: Choose column with gaps
2. Click **"Fill Down Empty Cells"**
3. ✓ Empty cells now contain value from previous non-empty cell

**Example**:
```
BEFORE Fill Down:
sample_id    study_id
SAMPLE001    STUDY-A
SAMPLE002    
SAMPLE003    
SAMPLE004    STUDY-B
SAMPLE005    

AFTER Fill Down:
sample_id    study_id
SAMPLE001    STUDY-A
SAMPLE002    STUDY-A     ← filled
SAMPLE003    STUDY-A     ← filled
SAMPLE004    STUDY-B
SAMPLE005    STUDY-B     ← filled
```

**Warning**: Fill down goes top-to-bottom. If first cell is empty, it will propagate that empty value!

---

### 🧹 Tool 4: Data Cleaning

#### Text Cleaning Operations

**What it does**: Applies standardization operations to text.

**When to use it**: Before ontology mapping, to clean up messy user input.

**Steps**:

1. **Select field**: Choose column to clean
2. **Select operations** (can choose multiple):

   | Operation | What It Does | Example |
   |-----------|--------------|---------|
   | **Trim whitespace** | Removes leading/trailing spaces | "  European  " → "European" |
   | **Remove extra spaces** | Consolidates multiple spaces | "East  Asian" → "East Asian" |
   | **Convert to lowercase** | All characters lowercase | "EUROPEAN" → "european" |
   | **Convert to UPPERCASE** | All characters uppercase | "european" → "EUROPEAN" |
   | **Title Case** | Capitalizes First Letter Of Each Word | "european union" → "European Union" |
   | **Remove special characters** | Keeps only letters, numbers, spaces | "Sample-#123!" → "Sample123" |
   | **Remove numbers** | Strips all digits | "Sample123" → "Sample" |

3. Click **"Preview Changes"**:
   - Notification shows how many values will change
   - Preview table shows before/after for first 10 changes
4. Review preview in **Curation Preview** section below
5. If satisfied, click **"Apply Cleaning"**
6. ✓ Changes applied to data

**Recommended combinations**:
- **For ontology mapping prep**: Trim + Remove extra spaces + Lowercase
- **For identifiers**: Trim + Remove special characters
- **For display**: Trim + Title Case

**Example**:
```
Original values:
"  European  "
"EUROPEAN"
"european-american"

After [Trim + Remove extra spaces + Lowercase]:
"european"
"european"
"europeanamerican"
```

#### Remove Duplicates

**What it does**: Deletes rows that have identical values in selected fields.

**When to use it**:
- Accidentally imported data twice
- Multiple entries for same sample
- Data copied/pasted incorrectly

**Steps**:

1. **Select fields for comparison**: Choose which columns define a "duplicate"
   - Example: If you select `sample_id`, any rows with same sample_id are duplicates
   - You can select multiple fields: `sample_id` + `study_id`
2. Click **"Remove Duplicates"**
3. ✓ Notification shows how many rows were removed
4. **First occurrence is kept**, others deleted

**Example**:
```
BEFORE (selecting sample_id for dedup):
sample_id    ancestry       age
SAMPLE001    European       45
SAMPLE001    African        50    ← duplicate
SAMPLE002    Asian          30

AFTER:
sample_id    ancestry       age
SAMPLE001    European       45    ← kept (first)
SAMPLE002    Asian          30
```

**Warning**: This permanently deletes rows! Make sure you select the right fields.

---

### 📊 Curation Preview Section

Located at bottom of Data Curation tab.

**Shows**:
- Before/after comparison when you preview operations
- Up to 10 example transformations
- Helps you verify changes before applying

**When it updates**:
- After clicking "Preview Changes" in cleaning operations
- When mapping results are displayed
- After bulk operations

---

## Quality Control

The **Quality Control** tab validates your data against the schema.

### Understanding Validation

**Three levels of issues**:

1. **Errors** (Red) - Critical problems that prevent data submission:
   - Missing required fields
   - Invalid data types (text in numeric field)
   - Values not in allowed list

2. **Warnings** (Yellow) - Potential problems to review:
   - Unusual patterns
   - Recommended fields missing
   - Values close to but not matching expected patterns

3. **Passed** (Green) - All checks passed

### Running Validation

**Option 1: Full Validation**
1. Click **"Run Full Validation"** button
2. Wait for progress bar
3. Review results in Validation Results box

**Option 2: Quick Checks**
- **Check Required Fields**: Just checks if required columns exist
- **Check Data Types**: Verifies integer/numeric fields

**Option 3: Clear Results**
- Click "Clear Results" to remove validation output

### Info Boxes (Top Row)

- **Status**: Overall pass/fail
- **Errors**: Count of critical errors
- **Warnings**: Count of warnings
- **Completeness**: Percentage of non-empty cells

### Reading Validation Results

Results displayed as text with sections:

```
=== VALIDATION RESULTS ===

Overall Status: ✓ PASSED / ✗ FAILED

ERRORS:
  [1] Required field 'sample_id' is missing
  [2] Field 'age' must be numeric

WARNINGS:
  [1] Field 'ancestry' has non-standard values
  [2] 15% of 'sex' values are empty

✓✓✓ Data is valid and ready for submission! ✓✓✓  (if no errors)
```

### Field Completeness Report

Table showing for each field:
- **Status**: Required/Optional/Not in schema
- **NonEmpty**: Count of filled cells
- **Total**: Total cells
- **PercentFilled**: Completeness percentage with visual bar

**Color coding**:
- Yellow: Required fields
- Blue: Optional fields
- Red: Fields not in schema (custom fields)

### Fixing Issues

1. Review errors/warnings in Validation Results
2. Note which fields have problems
3. Go to **Data Editor** tab
4. Fix the issues
5. Return to Quality Control and validate again
6. Repeat until all errors are resolved

---

## Ontology Browser

The **Ontology Browser** tab shows your schema definition.

### Schema Information Cards

Four metric cards showing:
- **Schema Version**: Current schema version
- **Total Fields**: Number of defined fields
- **Required Fields**: How many are mandatory
- **Dynamic Enums**: Fields with ontology-based validation

### Field Browser (Left Panel)

**Search fields**: Type to filter field list
**Filter by**: Show All/Required Only/Optional Only
**Select Field**: Dropdown of all fields - select to see details

### Field Details (Right Panel)

For selected field, shows:

**Basic Info**:
- Field name
- Type (character, integer, etc.)
- Required: Yes/No
- Multiple Values: Can it contain multiple values separated by delimiter?
- Uniqueness: Must values be unique?

**Description**: What the field represents

**Validation Rules** (if any):
- Pattern: Regex pattern values must match
- Allowed Values: Static list (shows "Static Enum" badge)
- Delimiter: For multi-value fields

**Ontology Information** (if any):
- Shows "Dynamic Enum" badge (purple gradient)
- Root Terms: Top-level ontology terms
- Property: Ontology relationship (children, descendants)
- Specific ontology terms allowed

### All Fields Reference (Bottom)

Sortable, filterable table of all fields with:
- Field name
- Type
- Required status
- Multi-value capability
- Validation type
- Description (truncated)

Use search boxes above columns to filter.

**Colors**:
- Yellow: Required fields
- Blue: Dynamic Enum validation
- Gray: Static Enum validation
- Green: Pattern validation

---

## Export

The **Export** tab lets you download your curated data.

### Export Settings

**Choose format**:
- **CSV**: Comma-separated, opens in Excel
- **TSV**: Tab-separated, good for Unix tools
- **JSON**: For programmatic use

**Export options**:
- ☑ **Export only if validation passes**: Prevents exporting data with errors
  - If validation failed and this is checked, export button won't work
  - Uncheck to export anyway (not recommended)

### Export Status Panel

Shows:
- Number of samples
- Number of fields
- Validation status
- Whether export is allowed

**Colors**:
- Green: Ready to export
- Red: Cannot export (validation failed and "only if validated" is checked)

### Downloading

1. Configure format and options
2. Click **"Download Export"** button
3. File downloads to your Downloads folder
4. Filename format: `metadata_export_2026-01-25.csv`

---

## Complete Workflow Example

Here's a full workflow from start to finish using the Data Curation tools.

### Scenario
You have a dataset with ancestry information entered by users as free text. You need to standardize this to HANCESTRO ontology IDs for submission to a repository.

### Step 1: Import Data
```r
# Launch app
library(OmicsMLRepoCuration)
launch_curation_app()

# In app: Import Data → Choose File → upload "my_samples.csv"
```

Your data looks like:
```
sample_id    ancestry           age    sex
SAMPLE001    European           45     Female
SAMPLE002    african american   32     male
SAMPLE003    EAST ASIAN         28     Female
SAMPLE004      European         55     Male
SAMPLE005    Hispanic           41     female
```

### Step 2: Clean the Data
Go to **Data Curation** tab.

**2a. Clean ancestry field**:
1. Select field: `ancestry`
2. Check operations:
   - ✓ Trim whitespace
   - ✓ Remove extra spaces
   - ✓ Title case
3. Click "Preview Changes"
4. Review preview: "african american" → "African American"
5. Click "Apply Cleaning"

Result:
```
ancestry
European
African American
East Asian
European
Hispanic
```

**2b. Clean sex field**:
1. Select field: `sex`
2. Check: Trim + Lowercase
3. Apply Cleaning

Result:
```
sex
female
male
female
male
female
```

### Step 3: Map Ancestry to HANCESTRO

**Still in Data Curation tab, Ontology Term Mapping section**:

1. Select field: `ancestry`
2. Target ontology: `HANCESTRO`
3. Suggestions: `3`
4. Click "Map Values to Ontology Terms"
5. Wait 15 seconds...

Results appear:

| OriginalValue | SuggestedID | SuggestedLabel | Score |
|---------------|-------------|----------------|-------|
| European | HANCESTRO:0005 | European | 1.00 |
| African American | HANCESTRO:0568 | African American | 0.98 |
| East Asian | HANCESTRO:0008 | East Asian | 0.97 |
| Hispanic | HANCESTRO:0014 | Hispanic or Latin American | 0.92 |

6. All scores are high! Select all rows (click first, shift-click last)
7. Click "Apply Selected Mappings"
8. ✓ Notification: "Applied 4 mappings"

### Step 4: Verify in Data Editor

Go to **Data Editor** tab.

Your data now shows:
```
sample_id    ancestry           age    sex
SAMPLE001    HANCESTRO:0005     45     female
SAMPLE002    HANCESTRO:0568     32     male
SAMPLE003    HANCESTRO:0008     28     female
SAMPLE004    HANCESTRO:0005     55     male
SAMPLE005    HANCESTRO:0014     41     female
```

Perfect! All ancestry values are now standardized ontology IDs.

### Step 5: Validate

Go to **Quality Control** tab.

1. Click "Run Full Validation"
2. Wait for results...
3. Results show:

```
Overall Status: ✓ PASSED
✓ No errors found
✓ No warnings
✓✓✓ Data is valid and ready for submission! ✓✓✓
```

### Step 6: Export

Go to **Export** tab.

1. Format: CSV
2. ☑ Export only if validation passes (checked)
3. Status shows: ✓ Ready to export!
4. Click "Download Export"
5. File saved: `metadata_export_2026-01-25.csv`

**Done!** Your data is now:
- Cleaned and standardized
- Mapped to ontology terms
- Validated
- Exported for submission

---

## Troubleshooting

### Common Issues

#### "Cannot export: validation failed"

**Problem**: Trying to export but validation has errors.

**Solutions**:
1. Go to Quality Control → Run Full Validation
2. Read error messages carefully
3. Fix errors in Data Editor
4. Validate again
5. OR uncheck "Export only if validation passes"

#### "No values to map in selected field"

**Problem**: Ontology Term Mapping found no values.

**Causes**:
- Field is empty
- All values are NA or blank

**Solutions**:
- Check Data Editor - does field have data?
- Try different field
- Add data first

#### "No valid ontology IDs found"

**Problem**: OxO mapping requires format "PREFIX:ID" but didn't find any.

**Causes**:
- Field contains plain text, not ontology IDs
- IDs are lowercase (must be uppercase)
- IDs missing prefix

**Solutions**:
- **First use Ontology Term Mapping** to convert text to IDs
- Check format: "NCIT:C2855" not "ncit:c2855" or "C2855"
- Select correct field that has IDs

#### "Mapping error: ..."

**Problem**: Ontology or OxO mapping failed.

**Common causes**:
- **No internet connection**: Both tools need internet
- **Ontology server down**: Try again later
- **Invalid ontology name**: Check spelling
- **Too many values**: May timeout with >1000 unique values

**Solutions**:
- Check internet connection
- Try again (servers may be temporarily busy)
- Try different ontology
- For large datasets, map in batches (filter first)

#### Mapping returns "No match" for all values

**Problem**: Ontology Term Mapping didn't find any matches.

**Causes**:
- Values are in wrong language (ontologies are often English)
- Values are too vague or too specific
- Typos in values
- Wrong ontology selected

**Solutions**:
- Clean data first (trim, fix typos)
- Try different ontology
- Check if values are standard terms
- Some values may need manual curation

#### Low mapping scores (< 0.7)

**Problem**: Mappings found but confidence is low.

**What it means**: The algorithm isn't confident these are correct matches.

**Solutions**:
- Review carefully before applying
- Check if suggested label makes sense
- Don't apply mappings you're unsure about
- Consider manual curation for these values
- Clean text first (typos reduce scores)

#### Fill Down propagates wrong values

**Problem**: Fill Down filled with incorrect value.

**Cause**: First cell was wrong, or structure wasn't what you expected.

**Solutions**:
- **Undo**: Go to Data Editor, manually fix
- Always check first non-empty cell before Fill Down
- Consider sorting data first if needed

#### Removed too many duplicates

**Problem**: Remove Duplicates deleted more rows than expected.

**Cause**: Selected fields don't uniquely identify rows.

**Prevention**:
- Carefully choose which fields define a duplicate
- Example: If you select only `sex`, all males are considered duplicates!
- Usually select: `sample_id` or `sample_id + study_id`

#### Changes not showing up

**Problem**: Made changes but don't see them.

**Solutions**:
- Changes in Data Editor save immediately - no save button needed
- Refresh table: Click another tab and come back
- Check you're looking at correct field
- For curation tools: Make sure you clicked "Apply" not just "Preview"

---

## Best Practices

### Data Entry
- ✓ Use consistent formatting from the start
- ✓ Avoid special characters in identifiers
- ✓ Use dropdown menus when available
- ✓ Don't use spaces in IDs

### Curation Workflow
1. **Import** → Load data
2. **Clean** → Remove whitespace, standardize case
3. **Map** → Convert to ontology terms
4. **Validate** → Check for errors
5. **Fix** → Correct any issues found
6. **Validate again** → Confirm fixes
7. **Export** → Download final data

### Ontology Selection
- **Ancestry/ethnicity**: HANCESTRO
- **Diseases**: MONDO (comprehensive) or NCIT (cancer focus)
- **Phenotypes**: HP (clinical) or EFO (experimental)
- When unsure: Try NCIT first (broadest coverage)

### Validation Strategy
- Validate early and often
- Fix errors before warnings
- Don't ignore warnings - review them
- Re-validate after every major change

### Safety
- Keep original files backed up
- Work on copies
- Test curation steps on small subset first
- Export regularly to save progress

---

## Keyboard Shortcuts

(Standard browser/app shortcuts)

- **Ctrl/Cmd + F**: Search in table
- **Tab**: Navigate between fields
- **Enter**: Save cell edit
- **Escape**: Cancel cell edit
- **Arrow keys**: Navigate cells in table

---

## Getting Help

### In-App Resources
- **Help tab**: Quick reference guide
- **Ontology Browser**: Field definitions and requirements
- **Validation messages**: Specific error explanations

### Documentation Files
- `USER_GUIDE.md`: This comprehensive guide
- `CURATION_FEATURES.md`: Technical details on curation tools
- `README.md`: Package overview
- `QUICKSTART.md`: Quick setup guide

### Package Functions
```r
# View help for specific functions
?mapNodes
?oxoMap
?validate_data_against_schema
?load_metadata_schema
```

### Support
- Check package documentation: `help(package = "OmicsMLRepoCuration")`
- Review vignettes: `browseVignettes("OmicsMLRepoCuration")`

---

## Appendix: Field Requirements

### Required Fields
(These must be present and non-empty)

- `sample_id`: Unique sample identifier
- `study_id`: Study identifier
- Additional required fields depend on your schema version

Check **Ontology Browser** tab → Schema Information to see your specific required fields.

### Field Formats

**Ontology IDs**: Must use format "PREFIX:ID"
- ✓ Valid: "NCIT:C2855", "HANCESTRO:0005"
- ✗ Invalid: "C2855", "ncit:c2855"

**Dates**: ISO format recommended
- Format: YYYY-MM-DD
- Example: "2026-01-25"

**Numbers**: No commas or units
- ✓ Valid: 45, 23.5
- ✗ Invalid: "45 years", "23,500"

**Multi-value fields**: Use specified delimiter (often pipe |)
- Example: "HANCESTRO:0005|HANCESTRO:0568"

---

**End of User Guide**

*This guide covers the core functionality of the Omics Metadata Manager Shiny app. For technical implementation details, see the package documentation and source code.*
