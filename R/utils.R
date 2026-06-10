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
#' getOntologies(terms = terms)
#'
#' @export
getOntologies <- function(terms, delim = ":") {

    ontologies <- c()
    for (i in seq_along(terms)) {
        onto <- strsplit(terms[i], delim)[[1]][1]
        isSNOMED <- letters_only(onto)
        if (isFALSE(isSNOMED)) {onto <- "SNOMED"}
        ontologies[i] <- onto
    }
    return(ontologies)
}

#' @rdname getOntologies
#' @export
get_ontologies <- function(terms, delim = ":") {
    .Deprecated("getOntologies")
    getOntologies(terms = terms, delim = delim)
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

#' Indicate if a term is obsolete
#' 
#' @importFrom rols olsOntology olsTerm
#' 
#' @param term Character; ontology term 
#' 
#' @return Boolean
#'
#' @export
#'
#' @examples
#' isObsolete("EFO:0005842")
#'
isObsolete <- function(term) {
    onto <- getOntologies(term)
    ontob <- olsOntology(onto)
    termob <- olsTerm(ontob, term)
    ind <- termob@is_obsolete
    return(ind)
}

#' @rdname isObsolete
#' @export
is_obsolete <- function(term) {
    .Deprecated("isObsolete")
    isObsolete(term)
}

#' Get replacement for obsolete term
#' 
#' @importFrom rols olsOntology olsTerm
#' 
#' @param term Character; ontology term id
#' 
#' @return Character; id of replacement term or "No replacement"
#' 
#' @export
#'
#' @examples
#' getReplacement("EFO:0005842")
#'
getReplacement <- function(term) {
    onto <- getOntologies(term)
    ontob <- olsOntology(onto)
    termob <- olsTerm(ontob, term)
    repitem <- termob@term_replaced_by

    if (length(repitem) > 0) {
        rep_split <- unlist(strsplit(repitem, "/"))
        raw_id <- rep_split[length(rep_split)]
        rep_id <- gsub("_", ":", raw_id)
    } else if (length(repitem) == 0) {
        rep_id <- "No replacement"
    }
    return(rep_id)
}

#' @rdname getReplacement
#' @export
get_replacement <- function(term) {
    .Deprecated("getReplacement")
    getReplacement(term)
}
