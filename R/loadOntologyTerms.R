#' Load precomputed ontology terms for schema validation
#'
#' Reads the `<prefix>_ontology_terms.json` artifact produced by the schema
#' registry's `build_ontology_artifacts.py` and converts it into the
#' `ontology_terms` structure consumed by [validateDataAgainstSchema()]. This is
#' the production source of the ontology term set that
#' `validateDataAgainstSchema()` documents as "supplied by the caller": it
#' materializes each ontology-backed field's `dynamic.enum` descendants and
#' `static.enum` terms (labels + synonyms) so dynamic/static enum validation can
#' run without ad-hoc term lists.
#'
#' @importFrom jsonlite fromJSON
#'
#' @param path A character(1). Path to a `*_ontology_terms.json` file, a JSON
#'   object keyed by field name where each value has `labels` (array) and
#'   `synonym_lookup` (object mapping synonym -> preferred label).
#'
#' @return A named list keyed by field name. Each element is a list with
#'   `labels` (character vector of preferred labels) and `synonym_lookup`
#'   (named character vector mapping each synonym to its preferred label),
#'   ready to pass as `ontology_terms` to [validateDataAgainstSchema()].
#'
#' @examples
#' \dontrun{
#' ot <- loadOntologyTerms("cmd_ontology_terms.json")
#' res <- validateDataAgainstSchema(data, schema, ontology_terms = ot)
#' }
#'
#' @export
loadOntologyTerms <- function(path) {
    if (!file.exists(path)) {
        stop("Ontology terms file not found: ", path)
    }
    raw <- jsonlite::fromJSON(path, simplifyVector = TRUE)

    lapply(raw, function(field) {
        labels <- unlist(field$labels, use.names = FALSE)
        sl <- unlist(field$synonym_lookup)
        list(
            labels = if (is.null(labels)) character(0) else as.character(labels),
            synonym_lookup = if (length(sl) > 0) sl else character(0)
        )
    })
}
