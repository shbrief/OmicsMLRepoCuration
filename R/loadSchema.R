# Helper functions to work with the YAML schema

#' Load metadata schema from YAML file
#'
#' This function reads a YAML schema file and returns its contents as a list
#' structure. The schema defines metadata fields, their types, validation rules,
#' and other properties.
#'
#' @param schema_file Character string specifying the path to the YAML schema
#'   file. Default is "schemas/curatedMetagenomicData_schema.yaml".
#'
#' @return A list containing the full schema structure with field definitions,
#'   validation rules, and metadata.
#'
#' @importFrom yaml read_yaml
#'
#' @examples
#' # Load schema from default location
#' schema_file <- system.file("schema", "cmd_schema.yaml",
#'                           package = "OmicsMLRepoCuration")
#' if (file.exists(schema_file)) {
#'   schema <- load_metadata_schema(schema_file)
#'   names(schema)
#' }
#'
#' @export
load_metadata_schema <- function(schema_file = "schema/cmd_schema.yaml") {
  schema <- yaml::read_yaml(schema_file)
  return(schema)
}

#' Get field definition from schema
#'
#' Retrieves the complete definition for a specific field from a schema object.
#' The field definition includes properties such as column name, class, validation
#' rules, and ontology information.
#'
#' @param schema A list object returned by \code{\link{load_metadata_schema}}.
#' @param field_name Character string specifying the name of the field to retrieve.
#'
#' @return A list containing the field definition with properties such as col_name,
#'   col_class, required, validation, ontology, etc. Returns an error if the field
#'   is not found.
#'
#' @examples
#' schema_file <- system.file("schema", "cmd_schema.yaml",
#'                           package = "OmicsMLRepoCuration")
#' if (file.exists(schema_file)) {
#'   schema <- load_metadata_schema(schema_file)
#'   # Get definition for a specific field
#'   # field_def <- get_field_definition(schema, "sample_id")
#' }
#'
#' @export
get_field_definition <- function(schema, field_name) {
  if (field_name %in% names(schema)) {
    return(schema[[field_name]])
  } else {
    stop(paste("Field", field_name, "not found in schema"))
  }
}

#' Get all required fields from schema
#'
#' Extracts the names of all fields marked as required in the schema. Required
#' fields must be present in any dataset validated against this schema.
#'
#' @param schema A list object returned by \code{\link{load_metadata_schema}}.
#'
#' @return A character vector containing the names of all required fields. Returns
#'   an empty character vector if no fields are marked as required.
#'
#' @examples
#' schema_file <- system.file("schema", "cmd_schema.yaml",
#'                           package = "OmicsMLRepoCuration")
#' if (file.exists(schema_file)) {
#'   schema <- load_metadata_schema(schema_file)
#'   required_fields <- get_required_fields(schema)
#'   print(required_fields)
#' }
#'
get_required_fields <- function(schema) {
  required <- c()
  for (field_name in names(schema)) {
    if (is.list(schema[[field_name]]) && 
        !is.null(schema[[field_name]]$required) &&
        schema[[field_name]]$required == TRUE) {
      required <- c(required, field_name)
    }
  }
  return(required)
}

#' Get fields by category
#'
#' Retrieves all field names that belong to a specific category from the schema.
#' Categories help organize related fields (e.g., demographic, clinical, technical).
#' Metadata sections such as schema_info, validation_rules, and metadata are
#' automatically excluded.
#'
#' @param schema A list object returned by \code{\link{load_metadata_schema}}.
#' @param category Character string specifying the category name to filter by.
#'   Examples include "demographic", "clinical", "technical".
#'
#' @return A character vector containing the names of all fields in the specified
#'   category. Returns an empty character vector if no fields match the category.
#'
#' @examples
#' schema_file <- system.file("schema", "cmd_schema.yaml",
#'                           package = "OmicsMLRepoCuration")
#' if (file.exists(schema_file)) {
#'   schema <- load_metadata_schema(schema_file)
#'   # Get all categories first
#'   categories <- get_all_categories(schema)
#'   if (length(categories) > 0) {
#'     fields <- get_fields_by_category(schema, categories[1])
#'     print(fields)
#'   }
#' }
#'
get_fields_by_category <- function(schema, category) {
    fields_in_category <- c()
    
    for (field_name in names(schema)) {
        # Skip metadata sections
        if (field_name %in% c("schema_info", "validation_rules", "metadata")) {
            next
        }
        
        field_def <- schema[[field_name]]
        if (is.list(field_def) && 
            !is.null(field_def$category) && 
            field_def$category == category) {
            fields_in_category <- c(fields_in_category, field_name)
        }
    }
    
    return(fields_in_category)
}

#' Get all available categories from schema
#'
#' Extracts all unique category names used in the schema. Categories are used to
#' group related fields and organize the schema structure. Metadata sections such
#' as schema_info, validation_rules, and metadata are excluded from the search.
#'
#' @param schema A list object returned by \code{\link{load_metadata_schema}}.
#'
#' @return A character vector containing unique category names found in the schema.
#'   Returns an empty character vector if no categories are defined.
#'
#' @examples
#' schema_file <- system.file("schema", "cmd_schema.yaml",
#'                           package = "OmicsMLRepoCuration")
#' if (file.exists(schema_file)) {
#'   schema <- load_metadata_schema(schema_file)
#'   categories <- get_all_categories(schema)
#'   print(categories)
#' }
#'
get_all_categories <- function(schema) {
    categories <- c()
    
    for (field_name in names(schema)) {
        if (field_name %in% c("schema_info", "validation_rules", "metadata")) {
            next
        }
        
        field_def <- schema[[field_name]]
        if (is.list(field_def) && !is.null(field_def$category)) {
            categories <- c(categories, field_def$category)
        }
    }
    
    return(unique(categories))
}

#' Validate data against schema
#'
#' Performs comprehensive validation of a data frame against a schema, checking
#' for required fields, data types, and validation patterns. Returns detailed
#' results including any errors or warnings encountered.
#'
#' @param data A data frame to validate against the schema.
#' @param schema A list object returned by \code{\link{load_metadata_schema}}.
#'
#' @return A list with three components:
#'   \describe{
#'     \item{valid}{Logical indicating whether the data passes validation (TRUE)
#'       or has errors (FALSE).}
#'     \item{errors}{Character vector of error messages for critical validation
#'       failures (e.g., missing required fields).}
#'     \item{warnings}{Character vector of warning messages for non-critical
#'       issues (e.g., type mismatches, pattern violations).}
#'   }
#'
#' @details
#' The validation checks include:
#' \itemize{
#'   \item Required field presence
#'   \item Data type matching (character, integer, numeric, double)
#'   \item Pattern validation using regular expressions
#'   \item Multiple values with static enums: For fields with multiplevalues=TRUE,
#'     a delimiter, and static enum patterns (pipe-separated values), the function
#'     splits each cell value by the delimiter and validates each individual value
#'     against the allowed enum values. This supports fields like 'feces_phenotype'
#'     and 'smoker' that allow multiple selections from a predefined list.
#' }
#'
#' @examples
#' schema_file <- system.file("schema", "cmd_schema.yaml",
#'                           package = "OmicsMLRepoCuration")
#' if (file.exists(schema_file)) {
#'   schema <- load_metadata_schema(schema_file)
#'   # Create sample data frame
#'   test_data <- data.frame(
#'     field1 = c("value1", "value2"),
#'     field2 = c(1, 2)
#'   )
#'   # Validate
#'   results <- validate_data_against_schema(test_data, schema)
#'   print(results$valid)
#'   if (length(results$errors) > 0) print(results$errors)
#' }
#'
#' @export
validate_data_against_schema <- function(data, schema) {
  validation_results <- list(
    valid = TRUE,
    errors = c(),
    warnings = c()
  )
  
  # Check required fields
  required_fields <- get_required_fields(schema)
  missing_required <- setdiff(required_fields, colnames(data))
  if (length(missing_required) > 0) {
    validation_results$valid <- FALSE
    validation_results$errors <- c(
      validation_results$errors,
      paste("Missing required fields:", paste(missing_required, collapse = ", "))
    )
  }
  
  # Check data types for each field
  for (col in colnames(data)) {
    if (col %in% names(schema)) {
      field_def <- schema[[col]]
      expected_class <- field_def$col_class
      
      # Type checking
      actual_class <- class(data[[col]])[1]
      if (!is.null(expected_class)) {
        type_matches <- switch(expected_class,
          "character" = is.character(data[[col]]),
          "integer" = is.integer(data[[col]]) || is.numeric(data[[col]]),
          "numeric" = is.numeric(data[[col]]),
          "double" = is.double(data[[col]]) || is.numeric(data[[col]]),
          TRUE
        )
        
        if (! type_matches) {
          validation_results$warnings <- c(
            validation_results$warnings,
            paste0("Field '", col, "' expected type '", expected_class, 
                   "' but found '", actual_class, "'")
          )
        }
      }
      
      # Validation for fields with multiple values and static enums
      # Check if field has multiplevalues=TRUE, a delimiter, and pattern (static enum)
      has_multiple_values <- !is.null(field_def$multiple_values) && field_def$multiple_values
      has_delimiter <- !is.null(field_def$validation$delimiter)
      has_pattern <- !is.null(field_def$validation$pattern)
      
      if (has_multiple_values && has_delimiter && has_pattern) {
        # Check if pattern looks like a static enum (contains |)
        pattern <- field_def$validation$pattern
        if (grepl("\\|", pattern)) {
          # This is a static enum - parse allowed values
          allowed_values <- strsplit(pattern, "\\|")[[1]]
          allowed_values <- trimws(allowed_values)
          
          delimiter <- field_def$validation$delimiter
          # Handle compound delimiters like <;>
          # Use fixed=TRUE for literal string matching
          non_na_values <- data[[col]][!is.na(data[[col]])]
          if (length(non_na_values) > 0) {
            for (val_idx in seq_along(non_na_values)) {
              cell_value <- non_na_values[val_idx]
              # Split by delimiter to get individual values (using fixed string split)
              individual_values <- strsplit(cell_value, delimiter, fixed = TRUE)[[1]]
              individual_values <- trimws(individual_values)
              individual_values <- individual_values[individual_values != ""]
              
              # Check each individual value against allowed values
              invalid_values <- individual_values[!individual_values %in% allowed_values]
              if (length(invalid_values) > 0) {
                validation_results$warnings <- c(
                  validation_results$warnings,
                  paste0("Field '", col, "' row ", val_idx, 
                         " has invalid values: ", paste(invalid_values, collapse = ", "),
                         ". Allowed values: ", paste(allowed_values, collapse = ", "))
                )
              }
            }
          }
        } else {
          # It's a regex pattern, use standard pattern matching
          non_na_values <- data[[col]][!is.na(data[[col]])]
          if (length(non_na_values) > 0) {
            invalid <- !grepl(pattern, non_na_values)
            if (any(invalid)) {
              validation_results$warnings <- c(
                validation_results$warnings,
                paste0("Field '", col, "' has ", sum(invalid), 
                       " values not matching pattern:  ", pattern)
              )
            }
          }
        }
      } else if (has_pattern) {
        # Standard pattern validation (no multiple values or delimiter)
        pattern <- field_def$validation$pattern
        non_na_values <- data[[col]][!is.na(data[[col]])]
        if (length(non_na_values) > 0) {
          invalid <- !grepl(pattern, non_na_values)
          if (any(invalid)) {
            validation_results$warnings <- c(
              validation_results$warnings,
              paste0("Field '", col, "' has ", sum(invalid), 
                     " values not matching pattern:  ", pattern)
            )
          }
        }
      }
    }
  }
  
  return(validation_results)
}

#' Generate R data frame template from schema field definition
#'
#' Converts a single field definition from the schema into a data frame row
#' matching the data dictionary format. This is useful for generating templates
#' or exporting schema information.
#'
#' @param schema A list object returned by \code{\link{load_metadata_schema}}.
#' @param field_name Character string specifying the name of the field to convert.
#'
#' @return A data frame with one row containing the field definition with columns:
#'   \describe{
#'     \item{col.name}{Field name}
#'     \item{col.class}{Data type (character, integer, numeric, etc.)}
#'     \item{uniqueness}{Uniqueness constraint}
#'     \item{requiredness}{"required" or "optional"}
#'     \item{multiplevalues}{Whether multiple values are allowed}
#'     \item{description}{Field description}
#'     \item{allowedvalues}{Pipe-separated allowed values or regex pattern}
#'     \item{ontology}{Pipe-separated ontology term IDs}
#'   }
#'
#' @examples
#' schema_file <- system.file("schema", "cmd_schema.yaml",
#'                           package = "OmicsMLRepoCuration")
#' if (file.exists(schema_file)) {
#'   schema <- load_metadata_schema(schema_file)
#'   # Convert first field to template
#'   field_names <- names(schema)
#'   if (length(field_names) > 0) {
#'     template_df <- schema_to_template_df(schema, field_names[1])
#'     print(template_df)
#'   }
#' }
#'
#' @export
schema_to_template_df <- function(schema, field_name) {
  field_def <- get_field_definition(schema, field_name)
  
  # Extract allowed values
  allowed_vals <- NA
  if (! is.null(field_def$validation$allowed_values)) {
    allowed_vals <- paste(field_def$validation$allowed_values, collapse = "|")
  } else if (!is.null(field_def$validation$pattern)) {
    allowed_vals <- field_def$validation$pattern
  }
  
  # Extract ontology
  ontology_val <- NA
  if (!is.null(field_def$ontology$terms)) {
    ontology_val <- paste(sapply(field_def$ontology$terms, function(x) x$id), 
                          collapse = "|")
  }
  
  df <- data.frame(
    col.name = field_def$col_name,
    col.class = field_def$col_class,
    uniqueness = field_def$uniqueness,
    requiredness = ifelse(field_def$required, "required", "optional"),
    multiplevalues = field_def$multiple_values,
    description = field_def$description,
    allowedvalues = allowed_vals,
    ontology = ontology_val,
    stringsAsFactors = FALSE
  )
  
  return(df)
}

#' Export schema to CSV format as data dictionary
#'
#' Converts the entire schema into a data dictionary format and either writes it
#' to a CSV file or returns it as a data frame. The data dictionary includes all
#' field definitions with their properties, validation rules, and ontology mappings.
#' Metadata sections are automatically excluded.
#'
#' @param schema A list object returned by \code{\link{load_metadata_schema}}.
#' @param output_file Character string specifying the path to the output CSV file.
#'   If \code{NULL} (default), the data dictionary is returned as a data frame
#'   without writing to disk.
#'
#' @return A data frame containing the complete data dictionary with columns:
#'   col.name, col.class, uniqueness, requiredness, multiplevalues, description,
#'   allowedvalues, and ontology. When output_file is specified, the data frame
#'   is also written to the CSV file.
#'
#' @examples
#' schema_file <- system.file("schema", "cmd_schema.yaml",
#'                           package = "OmicsMLRepoCuration")
#' if (file.exists(schema_file)) {
#'   schema <- load_metadata_schema(schema_file)
#'   # Return as data frame
#'   data_dict <- export_schema_to_csv(schema)
#'   head(data_dict)
#'   
#'   # Write to CSV file
#'   # temp_file <- tempfile(fileext = ".csv")
#'   # data_dict <- export_schema_to_csv(schema, temp_file)
#' }
#'
#' @importFrom utils write.csv
#' @export
export_schema_to_csv <- function(schema, output_file = NULL) {
  # Collect all field definitions
  all_fields <- list()
  
  for (field_name in names(schema)) {
    # Skip metadata and category sections
    if (field_name %in% c("schema_info", "field_categories", 
                          "validation_rules", "metadata")) {
      next
    }
    
    if (is.list(schema[[field_name]]) && 
        !is.null(schema[[field_name]]$col_name)) {
      all_fields[[field_name]] <- schema_to_template_df(schema, field_name)
    }
  }
  
  # Combine into single data frame
  data_dict <- do.call(rbind, all_fields)
  rownames(data_dict) <- NULL
  
  # Write to CSV
  if (!is.null(output_file)) {
      write.csv(data_dict, output_file, row.names = FALSE)
      message(paste("Data dictionary exported to:", output_file))
  }
  
  return(data_dict)
}

#' Convert schema table to YAML format
#'
#' Converts a data dictionary table (data frame) into a YAML schema format.
#' This is useful for creating or updating YAML schema files from CSV data
#' dictionaries or for round-trip conversions between formats.
#'
#' @param schema_table A data frame containing schema definitions with columns
#'   matching the data dictionary format: col.name, col.class, uniqueness,
#'   requiredness, multiplevalues, description, allowedvalues, ontology.
#' @param output_file Character string specifying the path to the output YAML file.
#'   If \code{NULL} (default), the schema is returned as a list without writing
#'   to disk.
#'
#' @return A list containing the schema in YAML-compatible format, with field
#'   definitions including validation rules and ontology mappings. When output_file
#'   is specified, the list is also written to the YAML file.
#'
#' @details
#' The function processes the following:
#' \itemize{
#'   \item Converts requiredness/required to boolean required field
#'   \item Parses allowedvalues as either regex patterns or pipe-separated lists
#'   \item Handles dynamic.enum column to create file-based ontology sources
#'   \item Processes dynamic.enum.property for filtering ontology terms
#'   \item Adds delimiter for multiple value fields
#'   \item Splits ontology IDs by pipe character for static ontologies
#'   \item Creates proper YAML structure with validation and ontology sections
#' }
#' 
#' The function supports two CSV formats:
#' \itemize{
#'   \item Old format: col.name, col.class, uniqueness, requiredness, multiplevalues, 
#'         description, allowedvalues, ontology
#'   \item New format: col.name, col.class, unique, required, multiplevalues, 
#'         description, allowedvalues, static.enum, dynamic.enum, 
#'         dynamic.enum.property, delimiter, separater, corpus.type
#' }
#'
#' @examples
#' # Convert to YAML format
#' yaml_schema <- table_to_yaml_schema(dict_df)
#' str(yaml_schema)
#' 
#' # Example with new format (dynamic enum)
#' dict_df_new <- data.frame(
#'   col.name = "disease",
#'   col.class = "character",
#'   unique = "non-unique",
#'   required = "optional",
#'   multiplevalues = TRUE,
#'   description = "Reported disease type",
#'   allowedvalues = NA,
#'   static.enum = NA,
#'   dynamic.enum = "NCIT:C7057;EFO:0000408",
#'   dynamic.enum.property = "descendant",
#'   delimiter = ";",
#'   separater = NA,
#'   corpus.type = "dynamic_enum",
#'   stringsAsFactors = FALSE
#' )
#' 
#' # Write to file
#' # temp_yaml <- tempfile(fileext = ".yaml")
#' # yaml_schema <- table_to_yaml_schema(dict_df, temp_yaml)
#'
#' @param schema_version Character string for schema version. Default is "1.0.0".
#' @param schema_name Character string for schema name. Default is "curatedMetagenomicData_metadata_schema".
#' @param schema_description Character string describing the schema. Default is "Metadata schema for curatedMetagenomicData package".
#'
#' @importFrom yaml write_yaml
#' @export
table_to_yaml_schema <- function(schema_table, 
                                  output_file = NULL,
                                  schema_version = "1.0.0",
                                  schema_name = "curatedMetagenomicData_metadata_schema",
                                  schema_description = "Metadata schema for curatedMetagenomicData package") {
  
  # Initialize schema with metadata
  yaml_schema <- list(
    schema_info = list(
      name = schema_name,
      version = schema_version,
      description = schema_description,
      last_updated = as.character(Sys.Date())
    )
  )
  
  for (i in seq_len(nrow(schema_table))) {
    row <- schema_table[i, ]
    field_name <- row$col.name
    
    # Build field definition
    field_def <- list(
      col_name = row$col.name,
      col_class = row$col.class,
      uniqueness = row$unique,
      required = ifelse(tolower(row$required) == "required", TRUE, FALSE),
      multiple_values = row$multiplevalues,
      description = row$description
    )
    
    # Add validation rules if present
    validation <- list()
    
    # Parse allowed values
    if (!is.na(row$allowedvalues) && row$allowedvalues != "") {
      # Check if it's a pattern or list of values
      if (grepl("^\\^|\\$$|\\[|\\]|\\{|\\}|\\(|\\)", row$allowedvalues)) {
        # Looks like a regex pattern
        validation$pattern <- row$allowedvalues
      } else {
        # Split by | to get allowed values
        allowed_vals <- strsplit(as.character(row$allowedvalues), "\\|")[[1]]
        allowed_vals <- trimws(allowed_vals)
        validation$allowed_values <- allowed_vals
      }
    }
    
    # Add delimiter if present
    if ("delimiter" %in% names(row) && !is.na(row$delimiter) && row$delimiter != "") {
      validation$delimiter <- row$delimiter
    }
    
    if (length(validation) > 0) {
      field_def$validation <- validation
    }
    
    # Add ontology information
    ontology <- list()
    
    # Handle dynamic enum ontology
    if ("dynamic.enum" %in% names(row) && !is.na(row$dynamic.enum) && row$dynamic.enum != "") {
      ontology_roots <- strsplit(as.character(row$dynamic.enum), ";")[[1]]
      ontology_roots <- trimws(ontology_roots)
      
      # Add roots information
      ontology$roots <- ontology_roots
      
      # Add property type if specified
      if ("dynamic.enum.property" %in% names(row) && !is.na(row$dynamic.enum.property) && row$dynamic.enum.property != "") {
        ontology$property <- row$dynamic.enum.property
      }
    } else if ("ontology" %in% names(row) && !is.na(row$ontology) && row$ontology != "") {
      # Handle static ontology column
      ontology_ids <- strsplit(as.character(row$ontology), "\\|")[[1]]
      ontology_ids <- trimws(ontology_ids)
      
      # Create ontology terms list
      terms <- lapply(ontology_ids, function(id) {
        list(id = id)
      })
      
      ontology$terms <- terms
    }
    
    if (length(ontology) > 0) {
      field_def$ontology <- ontology
    } else {
      field_def$ontology <- NULL
    }
    
    # Add field to schema
    yaml_schema[[field_name]] <- field_def
  }
  
  # Write to YAML file if output_file is specified
  if (!is.null(output_file)) {
    yaml::write_yaml(yaml_schema, output_file)
    message(paste("Schema exported to YAML:", output_file))
    return(invisible(yaml_schema))
  }
  
  return(yaml_schema)
}

#' Convert data dictionary to LinkML schema format
#'
#' Converts a data dictionary (from CSV or table) into a LinkML-compatible YAML
#' schema. LinkML is a modeling language for linked data that provides a formal
#' way to define schemas with rich semantics.
#'
#' @param schema_table A data frame containing the schema/data dictionary with
#'   columns: col.name, col.class, unique/uniqueness, required/requiredness,
#'   multiplevalues, description, allowedvalues, and optionally dynamic.enum,
#'   dynamic.enum.property, delimiter, etc.
#' @param schema_id Character string for the schema identifier URI. Default is
#'   "https://example.org/curatedMetagenomicData".
#' @param schema_name Character string for the schema name. Default is
#'   "curatedMetagenomicData".
#' @param schema_description Character string describing the schema. Default is
#'   "Metadata schema for curatedMetagenomicData package".
#' @param class_name Character string for the main data class name. Default is
#'   "MetadataRecord".
#' @param output_file Optional character string specifying the path to write the
#'   LinkML YAML file. If NULL, the schema is returned but not written to file.
#'
#' @return A list containing the LinkML schema structure with id, name, prefixes,
#'   classes, slots, and enums sections. When output_file is specified, the list
#'   is also written to the YAML file.
#'
#' @details
#' The function creates a LinkML schema with:
#' \itemize{
#'   \item Schema metadata (id, name, description, prefixes)
#'   \item A main class containing all fields as slots
#'   \item Slot definitions with ranges, patterns, and constraints
#'   \item Enum definitions for fields with controlled vocabularies
#'   \item Ontology mappings preserved in slot annotations
#' }
#'
#' Type mappings:
#' \itemize{
#'   \item character -> string
#'   \item integer -> integer
#'   \item numeric/double -> float
#' }
#'
#' @examples
#' # Load data dictionary
#' dict <- read.csv("inst/schema/cmd_data_dictionary.csv", stringsAsFactors = FALSE)
#' 
#' # Convert to LinkML format
#' linkml_schema <- table_to_linkml_schema(dict)
#' 
#' # Write to file
#' # linkml_schema <- table_to_linkml_schema(dict, 
#' #                    output_file = "inst/schema/cmd_schema.linkml.yaml")
#'
#' @param schema_version Character string for schema version. Default is "1.0.0".
#'
#' @importFrom yaml write_yaml
#' @export
table_to_linkml_schema <- function(schema_table, 
                                    schema_id = "https://example.org/curatedMetagenomicData",
                                    schema_name = "curatedMetagenomicData",
                                    schema_version = "1.0.0",
                                    schema_description = "Metadata schema for curatedMetagenomicData package",
                                    class_name = "MetadataRecord",
                                    output_file = NULL) {
  
  # Map R types to LinkML types
  type_mapping <- list(
    "character" = "string",
    "integer" = "integer",
    "numeric" = "float",
    "double" = "float"
  )
  
  # Initialize LinkML schema structure
  linkml_schema <- list(
    id = schema_id,
    name = schema_name,
    version = schema_version,
    description = schema_description,
    prefixes = list(
      linkml = "https://w3id.org/linkml/",
      NCIT = "http://purl.obolibrary.org/obo/NCIT_",
      EFO = "http://www.ebi.ac.uk/efo/EFO_",
      HANCESTRO = "http://purl.obolibrary.org/obo/HANCESTRO_",
      UBERON = "http://purl.obolibrary.org/obo/UBERON_",
      MRO = "http://purl.obolibrary.org/obo/MRO_",
      SNOMED = "http://purl.bioontology.org/ontology/SNOMEDCT/"
    ),
    default_prefix = schema_name,
    imports = list("linkml:types")
  )
  
  # Initialize slots and enums
  slots <- list()
  enums <- list()
  slot_names <- c()
  
  # Process each field
  for (i in seq_len(nrow(schema_table))) {
    row <- schema_table[i, ]
    field_name <- row$col.name
    slot_names <- c(slot_names, field_name)
    
    # Determine range (type)
    r_type <- row$col.class
    linkml_type <- type_mapping[[r_type]]
    if (is.null(linkml_type)) {
      linkml_type <- "string"  # default
    }
    
    # Build slot definition
    slot_def <- list(
      description = row$description,
      range = linkml_type
    )
    
    # Add required
    is_required <- ifelse("requiredness" %in% names(row), 
                         tolower(row$requiredness) == "required",
                         ifelse("required" %in% names(row), 
                               tolower(row$required) == "required", FALSE))
    if (is_required) {
      slot_def$required <- TRUE
    }
    
    # Add multivalued
    if (!is.na(row$multiplevalues) && row$multiplevalues) {
      slot_def$multivalued <- TRUE
    }
    
    # Add identifier constraint for unique fields
    uniqueness <- ifelse("uniqueness" %in% names(row), row$uniqueness, 
                        ifelse("unique" %in% names(row), row$unique, "non-unique"))
    if (uniqueness == "unique") {
      slot_def$identifier <- TRUE
    }
    
    # Handle validation patterns and enums
    if (!is.na(row$allowedvalues) && row$allowedvalues != "") {
      # Check if it's a pattern or enum
      if (grepl("^\\^|\\$$|\\[|\\]|\\{|\\}|\\+", row$allowedvalues)) {
        # Regex pattern
        slot_def$pattern <- row$allowedvalues
      } else if (grepl("\\|", row$allowedvalues)) {
        # Enum values
        enum_name <- paste0(field_name, "_enum")
        slot_def$range <- enum_name
        
        # Create enum definition
        allowed_vals <- strsplit(as.character(row$allowedvalues), "\\|")[[1]]
        allowed_vals <- trimws(allowed_vals)
        
        # Create permissible_values as named list with NULL values
        # This will write as "value: {}" in YAML which LinkML accepts
        permissible_values <- setNames(
          rep(list(NULL), length(allowed_vals)),
          allowed_vals
        )
        
        enums[[enum_name]] <- list(
          permissible_values = permissible_values
        )
      }
    }
    
    # Handle dynamic enums (ontology-based)
    if ("dynamic.enum" %in% names(row) && !is.na(row$dynamic.enum) && row$dynamic.enum != "") {
      # Parse ontology roots
      ontology_roots <- strsplit(as.character(row$dynamic.enum), ";")[[1]]
      ontology_roots <- trimws(ontology_roots)
      
      # Use string range instead of enum for dynamic enums
      slot_def$range <- "string"
      
      # Add annotations for ontology mapping
      slot_def$annotations <- list(
        ontology_roots = paste(ontology_roots, collapse = ", ")
      )
      
      if ("dynamic.enum.property" %in% names(row) && !is.na(row$dynamic.enum.property) && row$dynamic.enum.property != "") {
        slot_def$annotations$ontology_property <- row$dynamic.enum.property
      }
      
      # Add a comment to description about expected values
      slot_def$comments <- list(
        paste("Values should be descendants of:", paste(ontology_roots, collapse = ", "))
      )
    }
    
    slots[[field_name]] <- slot_def
  }
  
  # Create main class
  classes <- list()
  classes[[class_name]] <- list(
    description = paste("Main data class for", schema_name),
    slots = slot_names
  )
  
  # Assemble full schema
  linkml_schema$classes <- classes
  linkml_schema$slots <- slots
  if (length(enums) > 0) {
    linkml_schema$enums <- enums
  }
  
  # Write to YAML file if output_file is specified
  if (!is.null(output_file)) {
    yaml::write_yaml(linkml_schema, output_file)
    message(paste("LinkML schema exported to:", output_file))
    return(invisible(linkml_schema))
  }
  
  return(linkml_schema)
}