#' Get the top nodes for dynamic enum.
#'
#' @import dplyr
#' @importFrom OmicsMLRepoR get_ontologies
#' @importFrom stats na.omit
#'
#' @param curated_col A character (1). The curated column name to find
#' the dynamic enum node for
#' @param dd A data frame. Data dictionary including the `curated_col` under
#' its `col.name` column.
#'
addDynamicEnumNodes <- function(curated_col, dd) {

    ## Find the `curated_col` in the data dictionary
    colnames <- c(curated_col,
                  paste0("curated_", curated_col))
    ind <- which(dd$col.name %in% colnames)

    ## Stop if the `curated_col` doesn't exist in the data dictionary
    if (length(ind) == 0) {
        msg <- paste(curated_col, "doesn't exist in the provided data dictionary")
        stop(msg)
    }

    ## Separate the ontoloty term ids and their ontologies
    terms <- dd[[ind, "ontology"]] %>% strsplit(split = "\\|") %>%
        unlist %>% stats::na.omit %>% as.vector
    onto <- OmicsMLRepoR::get_ontologies(terms = terms, delim = ":")

    ## Remove SNOMED from the ontology term id
    terms <- gsub("SNOMED:", "", terms)

    ## Find the top nodes for dynamic enum
    topNodes <- commonNodes(ids = terms, dbs = onto)
    res <- paste0(topNodes$ontology_term_id, collapse = ";")

    ## Add dynamic enum node(s) to the data dictionary
    dd$dynamic_enum[ind] <- res
    dd$dynamic_enum_property[ind] <- "descendent"

    return(dd)
}
