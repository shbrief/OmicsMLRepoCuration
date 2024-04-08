#' Convert one-to-many map to one-to-one format.
#'
#' @import dplyr
#'
#' @param map A data frame. The original map featuring one-to-many mapping of
#' original values to curated values in need of updating.
#' @param delimiter A character(1). The delimiter used to separate values within
#' a single cell of the original map. Likely ";" or "<;>".
#'
#' @return A new data frame map featuring the same unique set of original values
#' with a one-to-one mapping scheme for curated values.
#' 
#' @export
convertMap <- function(map, delimiter){
    
    ## Initialize dataframe
    new_map <- data.frame(matrix(nrow=2000, ncol=0), "original_value"=NA, 
                          "curated_ontology"=NA, "curated_ontology_term_id"=NA,
                          "curated_ontology_term_db"=NA)
    
    ## Initialize row counter
    row <- 0
    
    ## Parse the concatenated values into unique rows
    for (cel in 1:length(map$curated_ontology)){
        values <- as.list(unlist(strsplit(map$curated_ontology[cel], delimiter)))
        for (val in values){
            indx <- match(val, values)
            row <- row + 1
            new_map$original_value[row] <- map$original_value[cel]
            new_map$curated_ontology[row] <- val
            new_map$curated_ontology_term_id[row] <- as.list(unlist(strsplit(map$curated_ontology_term_id[cel], delimiter)))[indx]
            new_map$curated_ontology_term_db[row] <- as.list(unlist(strsplit(as.character(new_map$curated_ontology_term_id[row]), ":")))[1]
        }
    }
    
    ## Remove extra rows
    new_map <- subset(new_map, !is.na(original_value))
    
    return(new_map)
}
