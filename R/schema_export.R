#' Generate R data frame template from schema field definition
#'
#' Converts a single field definition from the schema into a data frame row
#' matching the data dictionary format. This is useful for generating templates
#' or exporting schema information.
#'
#' @param schema A list object returned by \code{\link{loadMetadataSchema}}.
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
#'   schema <- loadMetadataSchema(schema_file)
#'   # Convert first field to template
#'   field_names <- names(schema)
#'   if (length(field_names) > 0) {
#'     template_df <- schemaToTemplateDf(schema, field_names[1])
#'     print(template_df)
#'   }
#' }
#'
#' @export
schemaToTemplateDf <- function(schema, field_name) {
  field_def <- getFieldDefinition(schema, field_name)
  
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
#' @param schema A list object returned by \code{\link{loadMetadataSchema}}.
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
#'   schema <- loadMetadataSchema(schema_file)
#'   # Return as data frame
#'   data_dict <- exportSchemaToCsv(schema)
#'   head(data_dict)
#'   
#'   # Write to CSV file
#'   # temp_file <- tempfile(fileext = ".csv")
#'   # data_dict <- exportSchemaToCsv(schema, temp_file)
#' }
#'
#' @importFrom utils write.csv
#' @export
exportSchemaToCsv <- function(schema, output_file = NULL) {
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
      all_fields[[field_name]] <- schemaToTemplateDf(schema, field_name)
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
#' yaml_schema <- tableToYamlSchema(dict_df)
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
#'   dynamic.enum = "NCIT:C7057|EFO:0000408",
#'   dynamic.enum.property = "descendant",
#'   delimiter = ";",
#'   separater = NA,
#'   corpus.type = "dynamic_enum",
#'   stringsAsFactors = FALSE
#' )
#' 
#' # Write to file
#' # temp_yaml <- tempfile(fileext = ".yaml")
#' # yaml_schema <- tableToYamlSchema(dict_df, temp_yaml)
#'
#' @param schema_version Character string for schema version. Default is "1.0.0".
#' @param schema_name Character string for schema name. Default is "curatedMetagenomicData_metadata_schema".
#' @param schema_description Character string describing the schema. Default is "Metadata schema for curatedMetagenomicData package".
#'
#' @importFrom yaml write_yaml
#' @export
tableToYamlSchema <- function(schema_table, 
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
      # Determine if this should be treated as an enum list or regex pattern
      # Check corpus.type if available
      is_enum <- FALSE
      if ("corpus.type" %in% names(row) && !is.na(row$corpus.type)) {
        corpus_type <- as.character(row$corpus.type)
        # Only split by | when corpus.type indicates it's an enum. Token-aware so
        # compound types (e.g. "dynamic_enum|static_enum") are recognized.
        is_enum <- any(trimws(strsplit(corpus_type, "\\|")[[1]]) %in%
                         c("custom_enum", "static_enum", "binary"))
      }
      
      if (is_enum) {
        # Split by | to get allowed values (enum list)
        allowed_vals <- strsplit(as.character(row$allowedvalues), "\\|")[[1]]
        allowed_vals <- trimws(allowed_vals)
        validation$allowed_values <- allowed_vals
      } else {
        # Treat as regex pattern
        validation$pattern <- row$allowedvalues
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
      ontology_roots <- strsplit(as.character(row$dynamic.enum), "\\|")[[1]]
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
#' linkml_schema <- tableToLinkmlSchema(dict)
#' 
#' # Write to file
#' # linkml_schema <- tableToLinkmlSchema(dict, 
#' #                    output_file = "inst/schema/cmd_schema.linkml.yaml")
#'
#' @param schema_version Character string for schema version. Default is "1.0.0".
#'
#' @importFrom yaml write_yaml
#' @export
tableToLinkmlSchema <- function(schema_table, 
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
    last_updated_on = as.character(Sys.Date()),
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
        
        # Align ontology term ids from the `static.enum` column (pipe-separated,
        # positional) so each permissible value carries its verified `meaning`.
        # A blank/missing id leaves that value's meaning null.
        meanings <- rep(NA_character_, length(allowed_vals))
        if ("static.enum" %in% names(row)) {
          se <- row[["static.enum"]]
          if (!is.na(se) && !se %in% c("", "NA")) {
            ids <- trimws(strsplit(as.character(se), "\\|")[[1]])
            n <- min(length(ids), length(allowed_vals))
            if (n > 0) meanings[seq_len(n)] <- ids[seq_len(n)]
          }
        }

        # value -> {meaning: <id>} when an id exists, else value -> NULL
        # (LinkML accepts a bare permissible value).
        permissible_values <- setNames(
          lapply(seq_along(allowed_vals), function(k) {
            if (!is.na(meanings[k]) && !meanings[k] %in% c("", "NA")) {
              list(meaning = meanings[k])
            } else {
              NULL
            }
          }),
          allowed_vals
        )
        
        enums[[enum_name]] <- list(
          permissible_values = permissible_values
        )
      }
    }
    
    # Handle dynamic enums (ontology-based): emit a LinkML `reachable_from`
    # dynamic enum so ontology-grounding consumers (e.g. metacurator, SPEC 070)
    # can bind the field to its ontology branch. One `include: reachable_from`
    # entry per root (roots may span ontologies, e.g. NCIT + EFO); LinkML unions
    # them. Ontology-key is derived from each root's CURIE prefix (NCIT:... ->
    # obo:ncit). A dynamic + static field (corpus.type "dynamic_enum;static_enum")
    # keeps any permissible_values already built from `allowedvalues`.
    if ("dynamic.enum" %in% names(row) && !is.na(row$dynamic.enum) && row$dynamic.enum != "") {
      ontology_roots <- trimws(strsplit(as.character(row$dynamic.enum), "\\|")[[1]])
      ontology_roots <- ontology_roots[!ontology_roots %in% c("", "NA")]

      # `children` -> direct subclasses only; anything else -> transitive descendants.
      prop <- "descendant"
      if ("dynamic.enum.property" %in% names(row) &&
          !is.na(row[["dynamic.enum.property"]]) &&
          !row[["dynamic.enum.property"]] %in% c("", "NA")) {
        prop <- row[["dynamic.enum.property"]]
      }
      is_direct <- identical(prop, "children")

      includes <- lapply(ontology_roots, function(root) {
        prefix <- sub(":.*$", "", root)
        list(reachable_from = list(
          source_ontology = paste0("obo:", tolower(prefix)),
          source_nodes = list(root),
          relationship_types = list("rdfs:subClassOf"),
          is_direct = is_direct
        ))
      })

      enum_name <- paste0(field_name, "_enum")
      enum_def <- list(include = includes)
      # Preserve static permissible_values already built from `allowedvalues`.
      if (!is.null(enums[[enum_name]]) && !is.null(enums[[enum_name]]$permissible_values)) {
        enum_def$permissible_values <- enums[[enum_name]]$permissible_values
      }
      enums[[enum_name]] <- enum_def
      slot_def$range <- enum_name

      # Human-readable hint alongside the machine-readable reachable_from.
      slot_def$comments <- list(
        paste0("Values should be ",
               if (is_direct) "direct children" else "descendants",
               " of: ", paste(ontology_roots, collapse = ", "))
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

# ---- Deprecated snake_case aliases (kept for backward compatibility) ----

#' @param ... Arguments passed to the camelCase function of the same name.
#' @rdname schemaToTemplateDf
#' @export
schema_to_template_df <- function(...) {
  .Deprecated("schemaToTemplateDf")
  schemaToTemplateDf(...)
}

#' @param ... Arguments passed to the camelCase function of the same name.
#' @rdname exportSchemaToCsv
#' @export
export_schema_to_csv <- function(...) {
  .Deprecated("exportSchemaToCsv")
  exportSchemaToCsv(...)
}

#' @param ... Arguments passed to the camelCase function of the same name.
#' @rdname tableToYamlSchema
#' @export
table_to_yaml_schema <- function(...) {
  .Deprecated("tableToYamlSchema")
  tableToYamlSchema(...)
}

#' @param ... Arguments passed to the camelCase function of the same name.
#' @rdname tableToLinkmlSchema
#' @export
table_to_linkml_schema <- function(...) {
  .Deprecated("tableToLinkmlSchema")
  tableToLinkmlSchema(...)
}
