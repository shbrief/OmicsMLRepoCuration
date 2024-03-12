#' Check that a character doesn't match any non-letter
#' @param x A character(1).
letters_only <- function(x) !grepl("[^A-Za-z]", x)

#' Check that a character doesn't match any non-number
#' @param x A character(1).
numbers_only <- function(x) !grepl("\\D", x)

#' Extract ontology from the ontology term id
#'
#' @param terms A character vector
#' @param delim A character. Delimiter between ontology and its id.
#' Default is `:`.
#'
#' @examples
#' terms <- c("HP:0001824", "MONDO:0010200", "NCIT:C122328")
#' get_ontologies(terms = terms)
#'
#' @export
get_ontologies <- function(terms, delim = ":") {

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
