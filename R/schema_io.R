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
#'   schema <- loadMetadataSchema(schema_file)
#'   names(schema)
#' }
#'
#' @export
loadMetadataSchema <- function(schema_file = "schema/cmd_schema.yaml") {
  schema <- yaml::read_yaml(schema_file)
  return(schema)
}

#' Get field definition from schema
#'
#' Retrieves the complete definition for a specific field from a schema object.
#' The field definition includes properties such as column name, class, validation
#' rules, and ontology information.
#'
#' @param schema A list object returned by \code{\link{loadMetadataSchema}}.
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
#'   schema <- loadMetadataSchema(schema_file)
#'   # Get definition for a specific field
#'   # field_def <- getFieldDefinition(schema, "sample_id")
#' }
#'
#' @export
getFieldDefinition <- function(schema, field_name) {
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
#' @param schema A list object returned by \code{\link{loadMetadataSchema}}.
#'
#' @return A character vector containing the names of all required fields. Returns
#'   an empty character vector if no fields are marked as required.
#'
#' @examples
#' schema_file <- system.file("schema", "cmd_schema.yaml",
#'                           package = "OmicsMLRepoCuration")
#' if (file.exists(schema_file)) {
#'   schema <- loadMetadataSchema(schema_file)
#'   required_fields <- getRequiredFields(schema)
#'   print(required_fields)
#' }
#' 
#' @export
getRequiredFields <- function(schema) {
  required <- c()
  for (field_name in names(schema)) {
    if (is.list(schema[[field_name]]) && 
        !is.null(schema[[field_name]]$required) &&
        isTRUE(schema[[field_name]]$required)) {
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
#' @param schema A list object returned by \code{\link{loadMetadataSchema}}.
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
#'   schema <- loadMetadataSchema(schema_file)
#'   # Get all categories first
#'   categories <- getAllCategories(schema)
#'   if (length(categories) > 0) {
#'     fields <- getFieldsByCategory(schema, categories[1])
#'     print(fields)
#'   }
#' }
#'
#' @export
#'
getFieldsByCategory <- function(schema, category) {
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
#' @param schema A list object returned by \code{\link{loadMetadataSchema}}.
#'
#' @return A character vector containing unique category names found in the schema.
#'   Returns an empty character vector if no categories are defined.
#'
#' @examples
#' schema_file <- system.file("schema", "cmd_schema.yaml",
#'                           package = "OmicsMLRepoCuration")
#' if (file.exists(schema_file)) {
#'   schema <- loadMetadataSchema(schema_file)
#'   categories <- getAllCategories(schema)
#'   print(categories)
#' }
#'
#' @export
#'
getAllCategories <- function(schema) {
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


# ---- Deprecated snake_case aliases (kept for backward compatibility) ----

#' @param ... Arguments passed to the camelCase function of the same name.
#' @rdname loadMetadataSchema
#' @export
load_metadata_schema <- function(...) {
  .Deprecated("loadMetadataSchema")
  loadMetadataSchema(...)
}

#' @param ... Arguments passed to the camelCase function of the same name.
#' @rdname getFieldDefinition
#' @export
get_field_definition <- function(...) {
  .Deprecated("getFieldDefinition")
  getFieldDefinition(...)
}

#' @param ... Arguments passed to the camelCase function of the same name.
#' @rdname getRequiredFields
#' @export
get_required_fields <- function(...) {
  .Deprecated("getRequiredFields")
  getRequiredFields(...)
}
