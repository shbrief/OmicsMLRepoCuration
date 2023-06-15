.getOntoInfo <- function(term, rows) {
    qry <- OlsSearch(q = term, rows = rows)
    qry <- olsSearch(qry)
    qdrf <- as(qry, "data.frame")
    qdrf <- qdrf[!duplicated(qdrf$obo_id),] # remove multiplicates
    return(qdrf)
}

.getOntoDB <- function(termId, db, id) {
    x <- strsplit(termId, split = "_|:")
    db <- unlist(x)[1]
    id <- unlist(x)[2]
    
    ol <- Ontologies()
    if (!tolower(db) %in% olsNamespace(ol)) {
        stop("The requested ontology database isn't available.")
    }
    targetdb <- Ontology(db)
    # allterms <- terms(targetdb) # Time consuming step. Save the snapshot for common ontology databases
    term <- term(targetdb, paste(toupper(db), id, sep = ":"))
}

#' Get the definition of ontology terms
#'
#' @import rols
#' 
#' @param term Character(1). The ontolgy term you want to check its definition.
#' @param qryOntoDB The ontology database of the input \code{term} comes from.
#' @param rows Integer(1).The maximum number of terms to look up. Default is 10. 
#' 
#' @return The description/definition of the \code{term} in \code{qryOntoDB}. 
#' If \code{qryOntoDB} is not specified, the data frame containing all the 
#' ontology databases including the requested term will be returned.
#' 
#' @examples
#' getDescription("Sitagliptin", "NCIT")
#' getDescription("Sitagliptin")
#' 
#' 
#' @export
getDescription <- function(term,
                           qryOntoDB = NULL,
                           rows = 10) {
    ontoInfo <- .getOntoInfo(term = term, rows = rows)
    
    if (is.null(qryOntoDB)) {
        res <- ontoInfo[, c("obo_id", "label", "description")]
    } else {
        if (!tolower(qryOntoDB) %in% ontoInfo$ontology_name) {
            stop("The term is not available in the quaried ontology database")
        } else {
            ind <- match(tolower(qryOntoDB), ontoInfo$ontology_name)
            res <- ontoInfo$description[[ind]]
        }
    }
    
    return(res)
}

#' Get the definition of ontology terms
#'
#' @param term Character(1). The ontolgy term you want to check its definition.
#' @param targetOntoDB A character vector containing the ontology databases you
#' want to look up the \code{term}. The other ontology databases you want to look for the 
#' same/similar term as the input \code{term}. 
#' @param rows Integer(1).The maximum number of terms to look up. Default is 10. 
#' 
#' @import rols
#' 
#' @export
getTermFromOtherDB <- function(term,
                               targetOntoDB,
                               rows = 10) {
    
    ontoInfo <- .getOntoInfo(term = term, rows = rows)
    ind <- match(tolower(qryOntoDB), ontoInfo$ontology_name)
    res <- ontoInfo[ind, c("obo_id", "label", "description")]
    
}