#' Split Column by Delimiter and/or Separator into Multiple Columns
#'
#' Generalized function to split a column containing delimiter and/or separator 
#' delimited values. This function is similar to the approach used in 
#' OmicsMLRepoR::getWideMetaTb and spreadMeta functions.
#'
#' @param data A data frame containing the column to split
#' @param targetCol Character(1). The name of the column to split
#' @param delim Character(1). Delimiter used to separate multiple values in the 
#'   same column (e.g., `<;>` or `;`). If provided alone without `sep`, creates 
#'   a "long" table with multiple rows. If provided with `sep`, first splits by 
#'   delimiter then by separator.
#' @param sep Character(1). Separator used to split column name and value 
#'   (e.g., `:`). For example, in "Bristol stool form score:1", the separator 
#'   is `:`. If NULL, only delimiter splitting is performed.
#' @param newColNames Character vector. Names for the new columns after splitting.
#'   - If both delim and sep are provided: can be a character vector for the 
#'     expected column names after splitting, or NULL to auto-extract from data
#'   - If only sep is provided: vector of length 2, or NULL for default names
#'   - If only delim is provided: not used (creates long table)
#' @param position Character(1). Where to split by separator: "last" (default) 
#'   splits at the last occurrence, "first" splits at the first occurrence.
#'   Only used when `sep` is provided.
#' @param remove Logical. If TRUE (default), remove the original column from 
#'   the output data frame
#' @param convert_na Logical. If TRUE (default), convert character "NA" to 
#'   logical NA values
#' @param expand_rows Logical. If TRUE and delim is provided, expand to multiple 
#'   rows (long format). If FALSE (default), expand to multiple columns (wide format).
#'
#' @return A data frame with split columns or expanded rows
#'
#' @examples
#' \dontrun{
#' # Example 1: Split by separator only (simple name:value split)
#' data <- data.frame(
#'   feces_phenotype = "Bristol stool form score (observable entity):1"
#' )
#' result <- splitColumnBySep(data, targetCol = "feces_phenotype", sep = ":")
#' 
#' # Example 2: Split by delimiter only (expand to multiple rows)
#' data <- data.frame(
#'   values = "value1<;>value2<;>value3"
#' )
#' result <- splitColumnBySep(data, targetCol = "values", delim = "<;>", expand_rows = TRUE)
#' 
#' # Example 3: Split by both delimiter and separator (wide format)
#' data <- data.frame(
#'   feature = "color:red<;>shape:round<;>size:medium"
#' )
#' result <- splitColumnBySep(data, targetCol = "feature", delim = "<;>", sep = ":")
#' 
#' # Example 4: Multiple entries with delimiter and separator
#' data <- data.frame(
#'   metadata = "age:45;bmi:28.5;height:175"
#' )
#' result <- splitColumnBySep(data, targetCol = "metadata", delim = ";", sep = ":")
#' }
#'
#' @export
splitColumnBySep <- function(data, 
                             targetCol,
                             delim = NULL,
                             sep = NULL,
                             newColNames = NULL,
                             position = "last",
                             remove = TRUE,
                             convert_na = TRUE,
                             expand_rows = FALSE) {
  
  # Validate inputs
  if (!is.data.frame(data)) {
    stop("`data` input should be a data frame.")
  }
  
  if (!targetCol %in% colnames(data)) {
    stop(paste0("Column '", targetCol, "' not found in data"))
  }
  
  if (is.null(delim) && is.null(sep)) {
    stop("At least one of `delim` or `sep` must be provided")
  }
  
  if (!is.null(sep) && !position %in% c("first", "last")) {
    stop("`position` must be either 'first' or 'last'")
  }
  
  # Get the column position
  col_position <- which(colnames(data) == targetCol)
  
  # Convert to character for splitting
  col_values <- as.character(data[[targetCol]])
  
  # Case 1: Only delimiter provided (expand to multiple rows - long format)
  if (!is.null(delim) && is.null(sep) && expand_rows) {
    return(.split_by_delim_long(data, targetCol, delim, col_position, 
                                remove, convert_na))
  }
  
  # Case 2: Only separator provided (split into 2 columns)
  if (is.null(delim) && !is.null(sep)) {
    return(.split_by_sep_only(data, targetCol, sep, newColNames, position, 
                              col_position, col_values, remove, convert_na))
  }
  
  # Case 3: Both delimiter and separator provided (wide format)
  if (!is.null(delim) && !is.null(sep)) {
    return(.split_by_delim_and_sep_wide(data, targetCol, delim, sep, 
                                        newColNames, position, col_position, 
                                        col_values, remove, convert_na))
  }
  
  # Case 4: Only delimiter provided but expand_rows = FALSE
  if (!is.null(delim) && is.null(sep) && !expand_rows) {
    warning("Delimiter provided without separator and expand_rows=FALSE. ",
            "Returning data with values concatenated by delimiter.")
    return(data)
  }
}


# Helper function: Split by delimiter only (long format - multiple rows)
.split_by_delim_long <- function(data, targetCol, delim, col_position, 
                                 remove, convert_na) {
  
  # Split values by delimiter
  split_values <- strsplit(as.character(data[[targetCol]]), delim, fixed = TRUE)
  
  # Calculate number of rows needed
  n_values <- sapply(split_values, length)
  
  # Expand data frame
  row_indices <- rep(1:nrow(data), n_values)
  data_expanded <- data[row_indices, , drop = FALSE]
  rownames(data_expanded) <- NULL
  
  # Fill in the split values
  data_expanded[[targetCol]] <- unlist(split_values)
  
  # Convert "NA" to logical NA if requested
  if (convert_na) {
    data_expanded[[targetCol]][data_expanded[[targetCol]] == "NA"] <- NA_character_
  }
  
  return(data_expanded)
}


# Helper function: Split by separator only (2 columns)
.split_by_sep_only <- function(data, targetCol, sep, newColNames, position,
                               col_position, col_values, remove, convert_na) {
  
  # Set default column names if not provided
  if (is.null(newColNames)) {
    newColNames <- c(targetCol, paste0(targetCol, "_value"))
  }
  
  if (length(newColNames) != 2) {
    stop("`newColNames` must be a character vector of length 2 when only `sep` is provided")
  }
  
  # Split the column based on position
  if (position == "last") {
    # Split at the last occurrence of separator
    split_values <- strsplit(col_values, sep, fixed = TRUE)
    
    col1_values <- sapply(split_values, function(x) {
      if (length(x) <= 1 || is.na(x[1])) {
        return(x[1])
      } else {
        return(paste(x[1:(length(x)-1)], collapse = sep))
      }
    })
    
    col2_values <- sapply(split_values, function(x) {
      if (length(x) <= 1) {
        return(NA_character_)
      } else {
        return(x[length(x)])
      }
    })
    
  } else { # position == "first"
    # Split at the first occurrence of separator
    sep_escaped <- gsub("([.|()\\^{}+$*?]|\\[|\\])", "\\\\\\1", sep)
    pattern <- paste0("^([^", sep_escaped, "]*)", sep_escaped, "(.*)$")
    
    col1_values <- sub(pattern, "\\1", col_values)
    col2_values <- sub(pattern, "\\2", col_values)
    
    # Handle cases where there's no separator
    no_sep <- !grepl(sep_escaped, col_values, fixed = FALSE)
    col2_values[no_sep] <- NA_character_
  }
  
  # Convert "NA" strings to logical NA if requested
  if (convert_na) {
    col1_values[col1_values == "NA"] <- NA_character_
    col2_values[col2_values == "NA"] <- NA_character_
  }
  
  # Create the new data frame
  return(.reconstruct_dataframe(data, col_position, remove, 
                                col1_values, col2_values, newColNames))
}


# Helper function: Split by both delimiter and separator (wide format)
.split_by_delim_and_sep_wide <- function(data, targetCol, delim, sep, 
                                         newColNames, position, col_position,
                                         col_values, remove, convert_na) {
  
  # Process each row
  processed_rows <- lapply(col_values, function(val) {
    if (is.na(val)) {
      return(list())
    }
    
    # Split by delimiter first
    parts <- strsplit(val, delim, fixed = TRUE)[[1]]
    
    # Split each part by separator
    result <- list()
    for (part in parts) {
      if (is.na(part) || part == "NA") next
      
      sep_split <- strsplit(part, sep, fixed = TRUE)[[1]]
      
      if (length(sep_split) >= 2) {
        if (position == "last") {
          key <- paste(sep_split[1:(length(sep_split)-1)], collapse = sep)
          value <- sep_split[length(sep_split)]
        } else { # first
          key <- sep_split[1]
          value <- paste(sep_split[2:length(sep_split)], collapse = sep)
        }
        result[[key]] <- value
      } else if (length(sep_split) == 1) {
        # No separator found, treat as a flag/indicator
        result[[sep_split[1]]] <- "TRUE"
      }
    }
    
    return(result)
  })
  
  # Extract all unique column names if not provided
  if (is.null(newColNames)) {
    all_keys <- unique(unlist(lapply(processed_rows, names)))
    newColNames <- sort(all_keys[!is.na(all_keys)])
  }
  
  # Create matrix for new columns
  new_data <- matrix(NA_character_, nrow = nrow(data), ncol = length(newColNames))
  colnames(new_data) <- newColNames
  
  # Fill in values
  for (i in seq_len(nrow(data))) {
    row_data <- processed_rows[[i]]
    for (col_name in names(row_data)) {
      if (col_name %in% newColNames) {
        new_data[i, col_name] <- row_data[[col_name]]
      }
    }
  }
  
  # Convert to data frame
  new_data_df <- as.data.frame(new_data, stringsAsFactors = FALSE)
  
  # Convert "NA" strings to logical NA if requested
  if (convert_na) {
    new_data_df[] <- lapply(new_data_df, function(x) {
      x[x == "NA"] <- NA_character_
      x
    })
  }
  
  # Combine with original data
  if (remove) {
    if (col_position == 1) {
      result <- cbind(new_data_df, data[, -col_position, drop = FALSE])
    } else if (col_position == ncol(data)) {
      result <- cbind(data[, -col_position, drop = FALSE], new_data_df)
    } else {
      result <- cbind(
        data[, 1:(col_position-1), drop = FALSE],
        new_data_df,
        data[, (col_position+1):ncol(data), drop = FALSE]
      )
    }
  } else {
    if (col_position == ncol(data)) {
      result <- cbind(data, new_data_df)
    } else {
      result <- cbind(
        data[, 1:col_position, drop = FALSE],
        new_data_df,
        data[, (col_position+1):ncol(data), drop = FALSE]
      )
    }
  }
  
  return(result)
}


# Helper function: Reconstruct data frame with new columns
.reconstruct_dataframe <- function(data, col_position, remove, 
                                  col1_values, col2_values, newColNames) {
  if (remove) {
    # Remove original column and add new columns at the same position
    if (col_position == 1) {
      data_new <- data.frame(
        setNames(list(col1_values), newColNames[1]),
        setNames(list(col2_values), newColNames[2]),
        data[, -col_position, drop = FALSE],
        stringsAsFactors = FALSE
      )
    } else if (col_position == ncol(data)) {
      data_new <- data.frame(
        data[, -col_position, drop = FALSE],
        setNames(list(col1_values), newColNames[1]),
        setNames(list(col2_values), newColNames[2]),
        stringsAsFactors = FALSE
      )
    } else {
      data_new <- data.frame(
        data[, 1:(col_position-1), drop = FALSE],
        setNames(list(col1_values), newColNames[1]),
        setNames(list(col2_values), newColNames[2]),
        data[, (col_position+1):ncol(data), drop = FALSE],
        stringsAsFactors = FALSE
      )
    }
  } else {
    # Keep original column and add new columns after it
    if (col_position == ncol(data)) {
      data_new <- data.frame(
        data,
        setNames(list(col1_values), newColNames[1]),
        setNames(list(col2_values), newColNames[2]),
        stringsAsFactors = FALSE
      )
    } else {
      data_new <- data.frame(
        data[, 1:col_position, drop = FALSE],
        setNames(list(col1_values), newColNames[1]),
        setNames(list(col2_values), newColNames[2]),
        data[, (col_position+1):ncol(data), drop = FALSE],
        stringsAsFactors = FALSE
      )
    }
  }
  
  return(data_new)
}


#' Apply Column Split to a File
#'
#' Reads a TSV file, splits a column by delimiter and/or separator, and writes 
#' to output file. This function is a convenient wrapper around splitColumnBySep 
#' for file operations.
#'
#' @param input_file Path to input TSV file
#' @param output_file Path to output TSV file (default: adds "_split" suffix to input file)
#' @param targetCol Character(1). The name of the column to split
#' @param delim Character(1). Delimiter used to separate multiple values (e.g., `<;>` or `;`)
#' @param sep Character(1). Separator used to split column name and value (e.g., `:`)
#' @param newColNames Character vector. Names for the new columns. See splitColumnBySep for details.
#' @param position Character(1). Where to split by separator: "last" (default) or "first"
#' @param remove Logical. If TRUE (default), remove the original column
#' @param convert_na Logical. If TRUE (default), convert character "NA" to logical NA
#' @param expand_rows Logical. If TRUE and delim is provided, expand to multiple rows
#' @param file_sep Character(1). Field separator for reading/writing file. Default is tab "\t"
#'
#' @return Invisibly returns the modified data frame
#'
#' @examples
#' \dontrun{
#' # Example 1: Split feces_phenotype by separator only
#' splitColumnBySep_file(
#'   input_file = "~/path/to/MetaCardis_2020_a_sample.tsv",
#'   targetCol = "feces_phenotype",
#'   sep = ":"
#' )
#' 
#' # Example 2: Split by delimiter and separator (wide format)
#' splitColumnBySep_file(
#'   input_file = "input.tsv",
#'   output_file = "output.tsv",
#'   targetCol = "feature",
#'   delim = "<;>",
#'   sep = ":"
#' )
#' 
#' # Example 3: Split by delimiter only (long format)
#' splitColumnBySep_file(
#'   input_file = "input.tsv",
#'   targetCol = "values",
#'   delim = ";",
#'   expand_rows = TRUE
#' )
#' }
#'
#' @export
splitColumnBySep_file <- function(input_file, 
                                  output_file = NULL,
                                  targetCol,
                                  delim = NULL,
                                  sep = NULL,
                                  newColNames = NULL,
                                  position = "last",
                                  remove = TRUE,
                                  convert_na = TRUE,
                                  expand_rows = FALSE,
                                  file_sep = "\t") {
  
  # Expand tilde in path
  input_file <- path.expand(input_file)
  
  # Check if input file exists
  if (!file.exists(input_file)) {
    stop(paste0("Input file not found: ", input_file))
  }
  
  # Read the file
  message("Reading file: ", input_file)
  data <- read.delim(input_file, sep = file_sep, stringsAsFactors = FALSE)
  
  # Apply the split
  split_msg <- character()
  if (!is.null(delim)) split_msg <- c(split_msg, paste0("delimiter '", delim, "'"))
  if (!is.null(sep)) split_msg <- c(split_msg, paste0("separator '", sep, "'"))
  message("Splitting '", targetCol, "' column by ", paste(split_msg, collapse = " and "), "...")
  
  data_split <- splitColumnBySep(
    data = data, 
    targetCol = targetCol,
    delim = delim,
    sep = sep,
    newColNames = newColNames,
    position = position,
    remove = remove,
    convert_na = convert_na,
    expand_rows = expand_rows
  )
  
  # Determine output file name
  if (is.null(output_file)) {
    # Get file extension
    file_ext <- tools::file_ext(input_file)
    file_base <- tools::file_path_sans_ext(input_file)
    output_file <- paste0(file_base, "_split.", file_ext)
  } else {
    output_file <- path.expand(output_file)
  }
  
  # Write the output
  message("Writing output to: ", output_file)
  write.table(data_split, 
              file = output_file, 
              sep = file_sep, 
              row.names = FALSE, 
              quote = FALSE)
  
  message("Done! Processed ", nrow(data_split), " rows.")
  
  invisible(data_split)
}


#' Split feces_phenotype Column (Wrapper Function)
#'
#' Convenience wrapper for splitColumnBySep specifically for feces_phenotype columns.
#' Splits a feces_phenotype column containing colon-separated values into two columns:
#' feces_phenotype (the term) and feces_phenotype_value (the numeric value).
#'
#' @param data A data frame containing a feces_phenotype column
#' @param column_name The name of the column to split (default: "feces_phenotype")
#' @param keep_original Logical, whether to keep the original column (default: FALSE)
#'
#' @return A data frame with the split columns
#'
#' @examples
#' \dontrun{
#' # Read the TSV file
#' data <- read.delim("path/to/MetaCardis_2020_a_sample.tsv", sep = "\t")
#' 
#' # Split the feces_phenotype column
#' data_split <- split_feces_phenotype(data)
#' 
#' # Or keep the original column
#' data_split <- split_feces_phenotype(data, keep_original = TRUE)
#' }
#'
#' @export
split_feces_phenotype <- function(data, 
                                   column_name = "feces_phenotype",
                                   keep_original = FALSE) {
  
  splitColumnBySep(
    data = data,
    targetCol = column_name,
    sep = ":",
    position = "last",
    remove = !keep_original,
    convert_na = TRUE
  )
}
