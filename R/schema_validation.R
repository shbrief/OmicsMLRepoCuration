#' Tokenize cell value(s) for enum/pattern validation
#'
#' Splits one or more cell values on a delimiter, trims whitespace, drops empty
#' tokens, and removes always-allowed wildcard values. Centralizes the
#' split/trim/drop-empty/filter-wildcard preamble shared by the enum, pattern,
#' and dynamic-enum validation branches.
#'
#' @param values Character vector of one or more raw cell values.
#' @param delimiter Character string delimiter, or NULL for single-token cells.
#' @param wildcard_values Character vector of always-allowed values to drop, or
#'   NULL to keep all tokens.
#'
#' @return A character vector of cleaned tokens.
#'
#' @keywords internal
.tokenizeCells <- function(values, delimiter, wildcard_values = NULL) {
  tokens <- if (!is.null(delimiter)) {
    unlist(strsplit(as.character(values), delimiter, fixed = TRUE))
  } else {
    as.character(values)
  }
  tokens <- trimws(tokens)
  tokens <- tokens[nzchar(tokens)]
  if (!is.null(wildcard_values) && length(wildcard_values) > 0) {
    tokens <- tokens[!tokens %in% wildcard_values]
  }
  tokens
}

#' Validate combined field values
#'
#' Internal helper function to validate combined field values where two fields
#' must be paired together (e.g., feces_phenotype and feces_phenotype_value).
#' This function checks that:
#' \itemize{
#'   \item Both fields have the same number of values after splitting by delimiter
#'   \item Each phenotype value is valid according to its enum
#'   \item Each measurement value matches the expected pattern
#'   \item The combined format "phenotype:value" pairs are correctly formed
#' }
#'
#' @param data A data frame containing the fields to validate
#' @param key_field Character string naming the key field (e.g., "feces_phenotype")
#' @param value_field Character string naming the value field (e.g., "feces_phenotype_value")
#' @param key_schema Field definition from schema for the key field
#' @param value_schema Field definition from schema for the value field
#' @param delimiter Character string used to split multiple values (e.g., "<;>")
#'
#' @return A character vector of warning messages. Empty if validation passes.
#'
#' @keywords internal
.validate_combined_fields <- function(data, key_field, value_field, 
                                       key_schema, value_schema, delimiter) {
  warnings <- c()
  
  # Skip if either field is not present in the data
  if (!key_field %in% colnames(data) || !value_field %in% colnames(data)) {
    return(warnings)
  }
  
  # Get the columns
  key_col <- data[[key_field]]
  value_col <- data[[value_field]]
  
  # Check each row
  for (row_idx in seq_len(nrow(data))) {
    key_val <- key_col[row_idx]
    value_val <- value_col[row_idx]
    
    # Skip if both are NA
    if (is.na(key_val) && is.na(value_val)) {
      next
    }
    
    # Error if only one is NA
    if (is.na(key_val) && !is.na(value_val)) {
      warnings <- c(warnings, 
        paste0("Row ", row_idx, ": '", value_field, "' has a value but '", 
               key_field, "' is missing"))
      next
    }
    if (!is.na(key_val) && is.na(value_val)) {
      warnings <- c(warnings,
        paste0("Row ", row_idx, ": '", key_field, "' has a value but '", 
               value_field, "' is missing"))
      next
    }
    
    # Split by delimiter
    key_values <- strsplit(as.character(key_val), delimiter, fixed = TRUE)[[1]]
    value_values <- strsplit(as.character(value_val), delimiter, fixed = TRUE)[[1]]
    
    # Trim whitespace
    key_values <- trimws(key_values)
    value_values <- trimws(value_values)
    
    # Remove empty strings
    key_values <- key_values[key_values != ""]
    value_values <- value_values[value_values != ""]
    
    # Check counts match
    if (length(key_values) != length(value_values)) {
      warnings <- c(warnings,
        paste0("Row ", row_idx, ": '", key_field, "' has ", length(key_values),
               " value(s) but '", value_field, "' has ", length(value_values),
               " value(s). They must have the same count."))
      next
    }
    
    # Validate individual key values against enum if present
    if (!is.null(key_schema$validation$allowed_values)) {
      allowed_keys <- key_schema$validation$allowed_values
      invalid_keys <- key_values[!key_values %in% allowed_keys]
      if (length(invalid_keys) > 0) {
        warnings <- c(warnings,
          paste0("Row ", row_idx, ": '", key_field, "' has invalid values: ",
                 paste(invalid_keys, collapse = ", "),
                 ". Allowed values: ", paste(allowed_keys, collapse = ", ")))
      }
    } else if (!is.null(key_schema$validation$pattern)) {
      pattern <- key_schema$validation$pattern
      if (grepl("\\|", pattern)) {
        # This is a static enum
        allowed_keys <- strsplit(pattern, "\\|")[[1]]
        allowed_keys <- trimws(allowed_keys)

        invalid_keys <- key_values[!key_values %in% allowed_keys]
        if (length(invalid_keys) > 0) {
          warnings <- c(warnings,
            paste0("Row ", row_idx, ": '", key_field, "' has invalid values: ",
                   paste(invalid_keys, collapse = ", "),
                   ". Allowed values: ", paste(allowed_keys, collapse = ", ")))
        }
      }
    }
    
    # Validate individual value_values against pattern if present
    if (!is.null(value_schema$validation$pattern)) {
      pattern <- value_schema$validation$pattern
      for (val_idx in seq_along(value_values)) {
        if (!grepl(pattern, value_values[val_idx])) {
          warnings <- c(warnings,
            paste0("Row ", row_idx, ": '", value_field, "' value '",
                   value_values[val_idx], "' (paired with '", 
                   key_values[val_idx], "') does not match pattern: ", pattern))
        }
      }
    }
    
    # Create combined format string for informational purposes
    # Format: "phenotype1:value1<;>phenotype2:value2"
    combined_pairs <- paste(key_values, value_values, sep = ":")
    combined_format <- paste(combined_pairs, collapse = delimiter)
    
    # Note: We could add this to a "info" section if needed
    # For now, we just validate the structure
  }
  
  return(warnings)
}

#' Validate values of an ontology-backed (dynamic_enum) field
#'
#' Internal helper that classifies each value of a dynamic_enum field against a
#' precomputed set of ontology terms. Values equal to a preferred ontology label
#' pass silently. Any other value is flagged with a warning: a value that is a
#' recognized ontology synonym is reported as "a recognized ontology synonym,
#' not the preferred label", and anything else as "not a recognized term".
#'
#' The warning deliberately does NOT name a specific preferred label, because a
#' short synonym can be shared by several ontology terms (e.g. "RA" is a synonym
#' of both \emph{Refractory Anemia} and \emph{Rheumatoid Arthritis}), so naming
#' one would often be wrong. Multi-valued cells are split on the field's
#' delimiter and each distinct token is reported once with its occurrence count,
#' rather than once per row. All findings are warnings (never errors).
#'
#' @param col_name Character; the field/column name (used in messages).
#' @param values The column's values (a vector from the data frame).
#' @param field_def The field definition from the schema (for the delimiter).
#' @param term_set One element of the \code{ontology_terms} list supplied to
#'   \code{\link{validateDataAgainstSchema}} (a list with \code{labels} and
#'   \code{synonym_lookup}), or NULL.
#' @param wildcard_values Character vector of always-allowed values to skip.
#'
#' @return A character vector of warning messages. Empty when \code{term_set} is
#'   NULL/empty (backward-compatible skip for fields with no bundled terms).
#'
#' @keywords internal
.validate_dynamic_enum <- function(col_name, values, field_def, term_set,
                                   wildcard_values) {
  warnings <- c()
  if (is.null(term_set) || length(term_set$labels) == 0) return(warnings)

  labels <- term_set$labels
  synonyms <- names(term_set$synonym_lookup)
  delimiter <- field_def$validation$delimiter

  non_na <- values[!is.na(values)]
  if (length(non_na) == 0) return(warnings)

  # Tokenize all cells (split multi-valued cells on the delimiter; single-valued
  # fields treat each cell as one token).
  tokens <- .tokenizeCells(non_na, delimiter, wildcard_values)
  if (length(tokens) == 0) return(warnings)

  # Report each distinct non-preferred token once, with its occurrence count.
  tok_counts <- table(tokens)
  bad <- names(tok_counts)[!names(tok_counts) %in% labels]
  for (tok in bad) {
    n <- as.integer(tok_counts[[tok]])
    rows_txt <- paste0("(", n, " row", if (n > 1L) "s" else "", ")")
    if (tok %in% synonyms) {
      warnings <- c(
        warnings,
        paste0("Field '", col_name, "': '", tok,
               "' is a recognized ontology synonym, not the preferred label; ",
               "replace it with the full preferred term ", rows_txt, ".")
      )
    } else {
      warnings <- c(
        warnings,
        paste0("Field '", col_name, "': '", tok,
               "' is not a recognized term for this ontology-backed field ",
               rows_txt, ".")
      )
    }
  }
  warnings
}

#' Validate data against schema
#'
#' Performs comprehensive validation of a data frame against a schema, checking
#' for required fields, data types, and validation patterns. Returns detailed
#' results including any errors or warnings encountered.
#'
#' @param data A data frame to validate against the schema.
#' @param schema A list object returned by \code{\link{loadMetadataSchema}}.
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
#'   \item Combined field validation: For certain field pairs (e.g., feces_phenotype
#'     and feces_phenotype_value), the function validates that both fields have the
#'     same number of values when split by delimiter, ensuring proper pairing of
#'     phenotype measurements with their corresponding values. The combined format
#'     follows the pattern "phenotype1:value1<;>phenotype2:value2".
#' }
#'
#' @examples
#' schema_file <- system.file("schema", "cmd_schema.yaml",
#'                           package = "OmicsMLRepoCuration")
#' if (file.exists(schema_file)) {
#'   schema <- loadMetadataSchema(schema_file)
#'   # Create sample data frame
#'   test_data <- data.frame(
#'     field1 = c("value1", "value2"),
#'     field2 = c(1, 2)
#'   )
#'   # Validate
#'   results <- validateDataAgainstSchema(test_data, schema)
#'   print(results$valid)
#'   if (length(results$errors) > 0) print(results$errors)
#' }
#'
#' @param wildcard_values A character vector of values that are allowed for all fields
#'   regardless of their validation rules. Default is c("Not applicable", "Not reported").
#'   Set to NULL to disable wildcard matching.
#' @param ontology_terms A named list (keyed by field name) of precomputed
#'   ontology terms used to validate ontology-backed (dynamic_enum) fields. Each
#'   element is a list with \code{labels} (character vector of allowed preferred
#'   labels) and \code{synonym_lookup} (named character vector mapping each
#'   ontology synonym to its preferred label). This is project-specific data: the
#'   calling project is responsible for generating and supplying it (see, e.g.,
#'   the curatedMetagenomicDataCuration package's bundled resource). Default is
#'   NULL, in which case dynamic_enum fields are not enum-validated. Fields absent
#'   from this list are likewise not enum-validated.
#'
#' @export
validateDataAgainstSchema <- function(data, schema,
                                          wildcard_values = c("Not applicable", "Not reported"),
                                          ontology_terms = NULL) {
  validation_results <- list(
    valid = TRUE,
    errors = c(),
    warnings = c()
  )

  # ontology_terms is project-specific and supplied by the caller. When absent,
  # dynamic_enum fields are simply not enum-validated (no bundled default here:
  # this package is generic validation infrastructure).
  if (is.null(ontology_terms)) {
    ontology_terms <- list()
  }

  # Check required fields
  required_fields <- getRequiredFields(schema)
  missing_required <- setdiff(required_fields, colnames(data))
  if (length(missing_required) > 0) {
    validation_results$valid <- FALSE
    validation_results$errors <- c(
      validation_results$errors,
      paste("Missing required fields:", paste(missing_required, collapse = ", "))
    )
  }

  # Check for columns not covered by schema
  extra_cols <- setdiff(colnames(data), names(schema))
  # Allow {character_column}_ontology_term_id columns (all character-class fields)
  categorical_cols <- names(schema)[vapply(schema, function(field_def) {
    !is.null(field_def$validation$allowed_values) ||
      !is.null(field_def$ontology) ||
      identical(field_def$col_class, "character")
  }, logical(1))]
  valid_ontology_id_cols <- paste0(categorical_cols, "_ontology_term_id")
  extra_cols <- setdiff(extra_cols, valid_ontology_id_cols)
  if (length(extra_cols) > 0) {
    validation_results$valid <- FALSE
    validation_results$errors <- c(
      validation_results$errors,
      paste("Columns not covered by schema:", paste(extra_cols, collapse = ", "))
    )
  }

  # Check data types for each field
  for (col in colnames(data)) {
    if (col %in% names(schema)) {
      field_def <- schema[[col]]
      expected_class <- field_def$col_class
      
      # Type checking (skip if all non-NA values are wildcards)
      actual_class <- class(data[[col]])[1]
      if (!is.null(expected_class)) {
        # Filter out wildcard values before type checking
        non_na_values <- data[[col]][!is.na(data[[col]])]
        if (!is.null(wildcard_values) && length(wildcard_values) > 0) {
          non_wildcard_values <- non_na_values[!non_na_values %in% wildcard_values]
        } else {
          non_wildcard_values <- non_na_values
        }
        
        # Only check type if there are non-wildcard values
        if (length(non_wildcard_values) > 0) {
          type_valid <- FALSE
          
          # For numeric types, try coercing and check if conversion is successful
          if (expected_class %in% c("integer", "numeric", "double")) {
            values_to_check <- non_wildcard_values
            # If field supports multiple values with a delimiter, split before
            # type-checking so that "1.5;2.3" is not mistakenly flagged as
            # non-numeric (the individual tokens after splitting are numeric).
            if (!is.null(field_def$multiple_values) && isTRUE(field_def$multiple_values) &&
                !is.null(field_def$validation$delimiter)) {
              delim <- field_def$validation$delimiter
              values_to_check <- unlist(strsplit(non_wildcard_values, delim, fixed = TRUE))
              values_to_check <- trimws(values_to_check)
              values_to_check <- values_to_check[nzchar(values_to_check)]
              if (!is.null(wildcard_values) && length(wildcard_values) > 0) {
                values_to_check <- values_to_check[!values_to_check %in% wildcard_values]
              }
            }
            # Try to coerce to numeric
            coerced <- suppressWarnings(as.numeric(values_to_check))
            # Valid if all non-wildcard values can be coerced (no NAs introduced)
            type_valid <- length(values_to_check) == 0L || all(!is.na(coerced))
          } else if (expected_class == "character") {
            # For character type, values can always be coerced to character
            type_valid <- TRUE
          } else {
            # For other types, use exact type matching
            type_valid <- switch(expected_class,
              "logical" = is.logical(data[[col]]),
              TRUE
            )
          }
          
          if (!type_valid) {
            validation_results$warnings <- c(
              validation_results$warnings,
              paste0("Field '", col, "' expected type '", expected_class, 
                     "' but found '", actual_class, 
                     "' with values that cannot be coerced to ", expected_class)
            )
          }
        }
      }
      
      # Validation for fields with multiple values and static enums
      # Check if field has multiplevalues=TRUE, a delimiter, and pattern (static enum)
      has_multiple_values <- !is.null(field_def$multiple_values) && field_def$multiple_values
      has_delimiter <- !is.null(field_def$validation$delimiter)
      has_pattern <- !is.null(field_def$validation$pattern)
      has_allowed_values <- !is.null(field_def$validation$allowed_values)
      has_ontology <- !is.null(field_def$ontology) &&
        !is.null(field_def$ontology$roots)
      
      if (has_multiple_values && has_delimiter && has_allowed_values) {
        # Field has multiple values with delimiter and allowed values list (enum)
        allowed_values <- field_def$validation$allowed_values
        delimiter <- field_def$validation$delimiter
        
        non_na_values <- data[[col]][!is.na(data[[col]])]
        if (length(non_na_values) > 0) {
          for (val_idx in seq_along(non_na_values)) {
            cell_value <- non_na_values[val_idx]
            # Split by delimiter and drop wildcards to get individual values
            individual_values <- .tokenizeCells(cell_value, delimiter,
                                                wildcard_values)
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
      } else if (has_multiple_values && has_delimiter && has_pattern) {
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
              # Split by delimiter and drop wildcards to get individual values
              individual_values <- .tokenizeCells(cell_value, delimiter,
                                                  wildcard_values)
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
          # It's a regex pattern with multiple values - split by delimiter and validate each
          delimiter <- field_def$validation$delimiter
          non_na_values <- data[[col]][!is.na(data[[col]])]
          if (length(non_na_values) > 0) {
            for (val_idx in seq_along(non_na_values)) {
              cell_value <- non_na_values[val_idx]
              # Split by delimiter and drop wildcards to get individual values
              individual_values <- .tokenizeCells(cell_value, delimiter,
                                                  wildcard_values)

              # Check each individual value against the pattern
              for (ind_val in individual_values) {
                if (!grepl(pattern, ind_val)) {
                  validation_results$warnings <- c(
                    validation_results$warnings,
                    paste0("Field '", col, "' row ", val_idx, 
                           " has value '", ind_val, 
                           "' not matching pattern: ", pattern)
                  )
                }
              }
            }
          }
        }
      } else if (has_allowed_values) {
        # Field has a list of allowed values (enum) - use exact matching
        allowed_values <- field_def$validation$allowed_values
        non_na_values <- data[[col]][!is.na(data[[col]])]
        if (length(non_na_values) > 0) {
          # Filter out wildcard values before checking
          if (!is.null(wildcard_values) && length(wildcard_values) > 0) {
            non_na_values <- non_na_values[!non_na_values %in% wildcard_values]
          }
          invalid_mask <- !non_na_values %in% allowed_values
          if (any(invalid_mask)) {
            invalid_vals <- unique(non_na_values[invalid_mask])
            validation_results$warnings <- c(
              validation_results$warnings,
              paste0("Field '", col, "' has ", sum(invalid_mask), 
                     " invalid values: ", paste(invalid_vals, collapse = ", "),
                     ". Allowed values: ", paste(allowed_values, collapse = ", "))
            )
          }
        }
      } else if (has_pattern) {
        # Standard pattern validation (no multiple values or delimiter)
        pattern <- field_def$validation$pattern
        non_na_values <- data[[col]][!is.na(data[[col]])]
        if (length(non_na_values) > 0) {
          # Filter out wildcard values before checking
          if (!is.null(wildcard_values) && length(wildcard_values) > 0) {
            non_na_values <- non_na_values[!non_na_values %in% wildcard_values]
          }
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

      # Validation for ontology-backed (dynamic_enum) fields. This is additive
      # (not part of the if/else-if ladder above) so a field that also carries a
      # static enum (e.g. treatment is "dynamic_enum;static_enum") still gets its
      # static check AND ontology preferred-label/synonym checking.
      if (has_ontology) {
        validation_results$warnings <- c(
          validation_results$warnings,
          .validate_dynamic_enum(col, data[[col]], field_def,
                                 ontology_terms[[col]], wildcard_values)
        )
      }
    }
  }

  # Check for combined field validations
  # Define field pairs that need combined validation
  combined_validations <- list(
    list(
      key_field = "feces_phenotype",
      value_field = "feces_phenotype_value"
    )
    # Add more combined validation pairs here if needed in the future
  )
  
  # Perform combined field validation for each pair
  for (pair in combined_validations) {
    key_field <- pair$key_field
    value_field <- pair$value_field
    
    # Check if both fields are defined in schema
    if (key_field %in% names(schema) && value_field %in% names(schema)) {
      key_schema <- schema[[key_field]]
      value_schema <- schema[[value_field]]
      
      # Get delimiter (should be same for both, but check key_field first)
      delimiter <- key_schema$validation$delimiter
      if (is.null(delimiter) && !is.null(value_schema$validation$delimiter)) {
        delimiter <- value_schema$validation$delimiter
      }
      
      # Perform combined validation if delimiter exists
      if (!is.null(delimiter)) {
        combined_warnings <- .validate_combined_fields(
          data, key_field, value_field,
          key_schema, value_schema, delimiter
        )
        validation_results$warnings <- c(validation_results$warnings, combined_warnings)
      }
    }
  }
  
  validation_results$has_warnings <- length(validation_results$warnings) > 0

  return(validation_results)
}


# ---- Deprecated snake_case aliases (kept for backward compatibility) ----

#' @param ... Arguments passed to the camelCase function of the same name.
#' @rdname validateDataAgainstSchema
#' @export
validate_data_against_schema <- function(...) {
  .Deprecated("validateDataAgainstSchema")
  validateDataAgainstSchema(...)
}
