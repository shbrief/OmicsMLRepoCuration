#' Extract urls for JSON trees from rols Term object
#'
#' @importFrom rols olsOntology olsTerm
#'
#' @param onto A character vector. Name(s) of ontologies that terms are from.
#' @param terms A character vector of ontology term IDs.
#'
#' @return A named list. Names of elements are original nodes (`terms`).
#' Each element is a character link to a JSON tree or the string "no tree".
#' 
#' @keywords internal
#'
#' @examples
#' term_ids <- c("NCIT:C2855", "NCIT:C35025", "NCIT:C122328")
#' # .getURLs("NCIT", term_ids)
.getURLs <- function(onto, terms) {
    
    ## Load ontology
    tryCatch({
        ontob <- rols::olsOntology(onto)
    }, error = function(e) {
        stop(paste0("Error retrieving ontology: \"", onto, "\""))
    })

    ## Get unique terms
    terms <- unique(terms)
    
    ## Initialize list to store retrieved links
    all_trees <- list()
    
    ## Loop through supplied terms
    for (i in 1:length(terms)) {
        print(paste0("Getting url for ", terms[i]))
        
        tryCatch({
            ## Get Term object and extract JSON tree link
            cur_trm <- olsTerm(ontob, terms[i])
            jstree <- cur_trm@links$jstree$href
            
        }, error = function(e) {
            print(e)
            print("Unable to access tree, proceeding to next term")
            jstree <<- "no tree"
        })
        
        if (!is.character(jstree)) {
            print("Unable to access tree, proceeding to next term")
            jstree <- "no tree"
        }
        
        ## Add link to list, named by term id
        all_trees <- c(all_trees, jstree)
        names(all_trees)[i] <- terms[i]
    }
    return(all_trees)
}


#' Retrieves ontology terms and database information for given term ids
#'
#' @importFrom rols OlsSearch olsSearch
#' @importFrom methods as
#' 
#' @param onto A character vector. Name(s) of ontologies that terms are from.
#' @param node A character vector of ontology term IDs.
#' 
#' @return Dataframe of submitted term IDs, term names, and term ontologies
#' 
#' @keywords internal
#'
#' @examples
#' onto <- c("FOODON", "CHEBI", "NCIT", "NCIT", "NCIT", "SNOMED", "SNOMED",
#' "SNOMED")
#' node <- c("FOODON:03600010", "CHEBI:166822", "NCIT:C1908", "NCIT:C41132",
#' "NCIT:C25218", "SNOMED:438451000124100", "SNOMED:372740001",
#' "SNOMED:48070003")
#'
#' # .displayNodes(onto = onto, node = node)
#'
.displayNodes <- function(onto, node) {
    
    ## Initialize dataframe to store term information
    dmat <- as.data.frame(matrix(nrow = sum(lengths(node)),
                                 ncol = 3,
                                 dimnames = list(c(), c("ontology_term",
                                                        "ontology_term_id",
                                                        "original_term_ontology"))))
    
    ## Save individual picked nodes with their respective ontologies
    dmat$ontology_term_id <- unname(unlist(node))
    dmat$original_term_ontology <- onto
    
    ## Loop through picked nodes and get additional information
    for (i in 1:nrow(dmat)) {
        curont <- dmat$original_term_ontology[i]
        curid <- dmat$ontology_term_id[i]
        print(paste0("Retrieving info for picked node ", curid))
        
        qry <- rols::OlsSearch(q = curid, exact = TRUE)
        qry <- rols::olsSearch(qry)
        qdrf <- methods::as(qry, "data.frame")
        
        if (curont %in% qdrf$ontology_prefix) {
            record <- qdrf[qdrf$ontology_prefix == curont, ][1,]
        } else if (TRUE %in% qdrf$is_defining_ontology) {
            record <- qdrf[qdrf$is_defining_ontology, ]
        } else {
            record <- qdrf[1, ]
        }
        dmat$ontology_term[i] <- record$label
    }
    return(dmat)
}

