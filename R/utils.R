#' Extract ontology from the ontology term id
#' 
#' @param terms A character vector
#' @param delim A character. Delimiter
#' 
#' @examples
#' terms <- c("HP:0001824", "MONDO:0010200", "NCIT:C122328")
#' get_ontologies(terms = terms, delim = "|")
#' 
#' @export
get_ontologies <- function(terms, delim) {
    
    ontologies <- c()
    for (i in seq_along(terms)) {
        onto <- strsplit(terms[i], delim)[[1]][1]
        isSNOMED <- letters_only(onto)
        if (isFALSE(isSNOMED)) {onto <- "SNOMED"}
        ontologies[i] <- onto
    }
    return(ontologies)
}

#' Extract ontology from the ontology term id
#' 
#' @param terms A character vector
#' @param delim A character. Delimiter
#' 
#' @return A character vector with unique values from the input `terms`
#' 
#' @export
strVsplit <- function(terms, delim) {
    res <- sapply(terms, strsplit, delim) %>%
        unlist %>%
        unique
    return(res)
}
