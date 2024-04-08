#' Removes excess semicolons/delimiters
#'
#' @import dplyr
#'
#' @param x A character(1). The value containing semicolons or other exc delimiters
#'  which need to be removed.
#' @param delimiter A character(1). The specific delimiter used to separate the 
#' values within `x`. Likely ";" or "<;>".
#'
#' @return A character value with the delimiter removed.
#'
#' @export
rmv_xtra_semis <- function(x, delimiter){
    x <- ifelse(startsWith(x, delimiter), sub(paste("^", delimiter, sep=""), "", x), x)
    return(ifelse(endsWith(x, delimiter), sub(paste(delimiter, "$", sep=""), "", x), x))
}

#' Format a list output for a single cell value
#'
#' @import dplyr
#'
#' @param vals_list A character(1). The list of values belonging to a single cell
#' to collapse.
#' @param delimiter A character(1). The delimiter used to separate values within
#' a single cell of the original curated data frame. Likely ";" or "<;>".
#'
#' @return A character value containing all values fom the list collapsed on the
#' delimiter.
#'
#' @export
format_list <- function(vals_list, delimiter){
    clean_list <- rmv_xtra_semis(paste(as.list(unique(vals_list)), collapse= delimiter), delimiter)
    
    return(clean_list)
}

#' Map original values to curated values and curated ontology term ids
#'
#' @import dplyr
#'
#' @param new_map A data frame. The complete updated map containing the original
#' values, curated values, and curated term ids for mapping.
#' @param col A character(1). The curated column name from the map to pull values 
#' from (either curated ontology terms or curated ontology term ids).
#' @param delimiter A character(1). The delimiter used to separate values within
#' a single cell of the original curated data frame. Likely ";" or "<;>".
#'
#' @return A character value containing all values fom the list collapsed on the
#' delimiter.
#'
#' @export
map_values <- function(new_map, col, delimiter){
    index <- grep(paste("^",y,"$",sep=""), new_map[,"original_value"], fixed=F)
    mapped_vals <- format_list(list_drop_empty(as.list(new_map[index, col])), delimiter)
    
    return(mapped_vals)
}

#' Update a column of curated data using a new mapping schema
#'
#' @import dplyr
#'
#' @param curated_data A data frame. The original version of the curated data
#' which needs to be updated using the new map.
#' @param map A data frame. The new or updated version of the map which 
#' corresponds to the curation of the selected dataset. The map must be 
#' formatted in a one-to-one schema of original to curated values.
#' @param column A character(1). The root name of the column which needs to be 
#' updated (excluding "original_" or "curated_").
#' @param delimiter A character(1). The delimiter used to separate values within
#' a single cell of the original curated data frame. Likely ";" or "<;>".
#'
#' @return A data frame of the updated curated data.
#'
#' @export
updateCuratedData <- function(curated_data, map, column, delimiter){
    
    # Create original column and curated column variables
    og_col <- paste("original", column, sep="_")
    new_col <- paste("curated", column, sep="_")
    
    # Iterate through merged column values
    for (x in 1:nrow(curated_data)){
        # Create a list of terms in the value
        original_terms <- unlist(strsplit(curated_data[x,og_col], delimiter))
        new_terms <- list()
        new_term_ids <- list()
        # Search for replacement terms in the ontology map
        new_terms <- lapply(original_terms, function(y) map_values("curated_ontology"))
        new_term_ids <- lapply(original_terms, function(y) map_values("curated_ontology_term_id"))
        new_terms <- format_list(list_drop_empty(new_terms), delimiter)
        new_term_ids <- format_list(list_drop_empty(new_term_ids), delimiter)
        # Concatenate new lists on delimiter to create curated value
        curated_data[x,new_col] <- format_list(as.list(unlist(strsplit(new_terms, delimiter))), delimiter)
        curated_data[x,paste(new_col, "ontology_term_id", sep="_")] <- format_list(as.list(unlist(strsplit(new_term_ids, delimiter))), delimiter)
        if(x %% 10000==0){print(x)}
    }
    
    # Replace empty values from curated columns with "NA"
    new_curated_df <- data.frame(lapply(curated_data, function(x) gsub("^$", NA, x)))
    
    return(new_curated_df)
}
