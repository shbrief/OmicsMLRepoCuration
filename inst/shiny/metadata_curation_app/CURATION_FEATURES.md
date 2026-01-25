# Data Curation Features

## Overview

The **Data Curation** tab provides comprehensive tools for standardizing, mapping, and cleaning metadata values. These tools integrate with the OmicsMLRepoCuration package functions to enable intelligent, ontology-aware data curation.

## Features

### 1. Ontology Term Mapping

**Purpose**: Map free-text values to standardized ontology terms using intelligent search.

**How it works**:
- Uses the `mapNodes()` function from OmicsMLRepoCuration
- Searches ontology databases (HANCESTRO, NCIT, EFO, HP, MONDO) for best matches
- Returns multiple suggestions with similarity scores
- Allows manual selection of best matches before applying

**Usage**:
1. Select the field containing free-text values
2. Choose target ontology
3. Set number of suggestions per value (1-10)
4. Click "Map Values to Ontology Terms"
5. Review results table with scores
6. Select desired mappings (multi-select supported)
7. Click "Apply Selected Mappings" to update your data

**Example Use Case**:
- Field: `ancestry` contains values like "European", "African American", "East Asian"
- Map to: HANCESTRO ontology
- Result: "European" → "HANCESTRO:0005", "African American" → "HANCESTRO:0568", etc.

---

### 2. Cross-Ontology Mapping (OxO)

**Purpose**: Convert ontology terms from one ontology to equivalent terms in another ontology.

**How it works**:
- Uses the `oxoMap()` function with the Ontology Xref Service (OxO) API
- Supports mapping distances: 1 (direct), 2 (one hop), 3 (two hops)
- Returns all available mappings with distance information

**Usage**:
1. Select field containing ontology IDs (format: "PREFIX:ID", e.g., "NCIT:C2855")
2. Choose target ontology
3. Set mapping distance (1 = direct mappings only, 2-3 = include indirect mappings)
4. Click "Map Across Ontologies"
5. Review results showing source → target mappings

**Example Use Case**:
- Convert NCIT disease codes to MONDO disease ontology
- Convert EFO terms to HANCESTRO for ancestry standardization
- Map HP (Human Phenotype) terms to NCIT

---

### 3. Bulk Operations

#### Find and Replace
**Purpose**: Search and replace text values across entire field.

**Features**:
- Case-sensitive or case-insensitive matching
- Whole word matching option
- Preview before applying changes
- Shows count of matches found

**Usage**:
1. Select field
2. Enter find text and replacement text
3. Configure options (case sensitive, whole word)
4. Click "Preview" to see match count
5. Click "Apply Changes" to execute replacement

**Example Use Case**:
- Standardize "Male" / "male" / "M" → "male"
- Replace abbreviated values: "Eur" → "European"

#### Fill Down
**Purpose**: Fill empty cells with the value from the cell above.

**Usage**:
1. Select field with gaps
2. Click "Fill Down Empty Cells"
3. Empty cells inherit value from previous non-empty cell

**Example Use Case**:
- Complete missing study IDs when samples are grouped
- Fill repeated metadata values

---

### 4. Data Cleaning

#### Text Cleaning Operations
**Purpose**: Standardize text formatting and content.

**Available Operations**:
- **Trim whitespace**: Remove leading/trailing spaces
- **Remove extra spaces**: Consolidate multiple spaces to single space
- **Convert to lowercase**: Standardize case (useful for controlled vocabularies)
- **Convert to uppercase**: All caps
- **Title case**: Capitalize first letter of each word
- **Remove special characters**: Keep only alphanumeric and spaces
- **Remove numbers**: Strip all numeric characters

**Usage**:
1. Select field
2. Check desired operations (multiple selections allowed)
3. Click "Preview Changes" to see sample transformations
4. Click "Apply Cleaning" to execute

**Example Use Case**:
- Clean user-entered values: "  European  " → "european"
- Remove special characters from identifiers: "Sample-#123" → "Sample123"
- Standardize case for ontology matching

#### Remove Duplicates
**Purpose**: Eliminate duplicate rows based on selected fields.

**Usage**:
1. Select one or more fields to use for duplicate detection
2. Click "Remove Duplicates"
3. First occurrence of each unique combination is kept
4. Notification shows number of rows removed

**Example Use Case**:
- Remove duplicate sample entries based on sample_id
- Eliminate duplicate subject records using subject_id + study_id

---

## Workflow Recommendations

### Typical Curation Workflow:

1. **Import Data** → Load your raw metadata file
2. **Data Cleaning** → Apply text cleaning operations first
   - Trim whitespace
   - Remove extra spaces
   - Standardize case if needed
3. **Ontology Mapping** → Map free-text values to standard terms
   - Use mapNodes for converting text to ontology IDs
   - Review and select best matches
4. **Cross-Ontology Mapping** → Convert between ontologies if needed
   - Useful when different fields use different ontology standards
5. **Bulk Operations** → Final standardization
   - Find/replace for remaining inconsistencies
   - Fill down for repeated values
6. **Quality Control** → Validate against schema
7. **Export** → Download curated data

### Best Practices:

- **Always preview before applying**: Use preview buttons to check changes
- **Work on copies**: The app modifies data in-place, so work incrementally
- **Validate frequently**: Run validation after major curation steps
- **Check mapping scores**: Higher scores (closer to 1.0) indicate better ontology matches
- **Use appropriate ontologies**:
  - HANCESTRO: Ancestry/ethnicity
  - NCIT: Cancer, diseases, general biomedical terms
  - EFO: Experimental factors, phenotypes
  - HP: Human phenotypes, clinical features
  - MONDO: Diseases

---

## Technical Details

### Functions Used:
- **mapNodes()**: Intelligent ontology term search and mapping
- **oxoMap()**: Cross-ontology term translation via OxO API
- **dplyr::distinct()**: Duplicate removal
- Base R text processing: gsub(), trimws(), toupper(), tolower()

### Data Requirements:
- For ontology mapping: Any text field
- For OxO mapping: Field must contain valid ontology IDs (format: "PREFIX:ID")
- For all operations: Data must be loaded in the Data Editor

### Performance Notes:
- Ontology mapping can take 10-30 seconds for large datasets (100+ unique values)
- OxO mapping requires internet connection to EBI API
- Bulk text operations are fast (<1 second typically)

---

## Troubleshooting

**"No values to map"**:
- Field is empty or contains only NA/blank values
- Select a different field

**"No valid ontology IDs found"**:
- OxO requires format like "NCIT:C2855", "EFO:0000228"
- Check your field contains properly formatted IDs

**"Mapping error"**:
- Check internet connection (required for API calls)
- Ontology server may be temporarily unavailable
- Try again or use different ontology

**Low mapping scores**:
- Values may not exist in selected ontology
- Try different ontology
- Check for typos in original values
- Consider manual curation for unclear terms

---

## Example Session

```r
# 1. Load demo data
library(OmicsMLRepoCuration)
launch_curation_app()

# In the app:
# 2. Import Data → Load Demo Data
# 3. Data Curation → Ontology Term Mapping
#    - Field: ancestry
#    - Ontology: HANCESTRO
#    - Suggestions: 3
#    - Click "Map Values to Ontology Terms"
# 4. Review results, select best matches
# 5. Click "Apply Selected Mappings"
# 6. Quality Control → Run Full Validation
# 7. Export → Download CSV
```

---

## Future Enhancements

Potential additions:
- Batch undo/redo functionality
- Curation history log
- Custom ontology sources
- AI-assisted value suggestion
- Bulk import of mapping dictionaries
- Export curation rules for reuse

---

**Last Updated**: January 24, 2026  
**Package**: OmicsMLRepoCuration v0.1.2
