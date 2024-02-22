#' Populate the data dictionary template with the information for a specific attribute(s)
#'
#' @param template_dd A data frame. Template data dictionary containing eight
#' columns - "col.name", "col.class", "uniqueness", "requiredness",
#' "multiplevalues", "description", "allowedvalues", "ontology"
#' @param attr_dd A data frame. Populated data dictionary for a specific
#' attribute(s). It should contains the same columns as `template_dd` (i.e.,
#' the same number and the same name of the columns).
#'
#' @return A data frame, an input for the `template_dd` argument, updated with
#' the `attr_dd` contents.
#'
#' @export
fillDataDictionary <- function(template_dd, attr_dd) {
    attr_dd <- attr_dd[order(attr_dd$col.name),]
    ind <- which(template_dd$col.name %in% attr_dd$col.name)
    template_dd[ind,] <- attr_dd[colnames(template_dd)]
    return(template_dd)
}
