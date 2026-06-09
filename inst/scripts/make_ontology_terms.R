#!/usr/bin/env Rscript
#
# make_ontology_terms.R
# -----------------------------------------------------------------------------
# MAINTENANCE GENERATOR (run by a maintainer; commit the output).
#
# Precomputes the preferred labels and synonyms for every dynamic_enum field in
# the cMD data dictionary by querying the source ontologies (NCIT, EFO, UBERON,
# HANCESTRO, MRO, ...) through EBI OLS via the `rols` package, and writes:
#
#     inst/extdata/cmd_ontology_terms.csv
#         columns: field, term_id, label, synonym
#         - one row per (term, synonym)
#         - a row with synonym = "" carries only the term's preferred label
#
# This file is consumed offline by `validate_data_against_schema()` so that
# metadata validation never needs network/ontology access at validation time.
#
# REQUIRES NETWORK. Re-run this script whenever the source ontologies update,
# then rebuild/re-release the package so CI picks up the refreshed snapshot.
#
# Usage:  Rscript inst/scripts/make_ontology_terms.R
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
    library(rols)
    library(OmicsMLRepoCuration)  # get_ontologies()
})

## Resolve package root from this script's location (inst/scripts/<file>) so the
## script works regardless of the current working directory.
.args <- commandArgs(trailingOnly = FALSE)
.file_arg <- grep("^--file=", .args, value = TRUE)
if (length(.file_arg)) {
    script_path <- normalizePath(sub("^--file=", "", .file_arg))
    pkg_root <- dirname(dirname(dirname(script_path)))
} else {
    pkg_root <- getwd()
}

dict_path <- file.path(pkg_root, "inst", "schema", "cmd_data_dictionary.csv")
out_path  <- file.path(pkg_root, "inst", "extdata", "cmd_ontology_terms.csv")

message("Reading dictionary: ", dict_path)
dict <- read.csv(dict_path, check.names = FALSE, stringsAsFactors = FALSE)

## dynamic_enum fields that actually declare an ontology root.
is_dyn <- grepl("dynamic_enum", dict[["corpus.type"]])
has_root <- !is.na(dict[["dynamic.enum"]]) & nzchar(dict[["dynamic.enum"]])
dyn <- dict[is_dyn & has_root, , drop = FALSE]
message("dynamic_enum fields with roots: ",
        paste(dyn[["col.name"]], collapse = ", "))

## Collect (term_id, label, synonyms) for the descendants/children of one root.
collect_root <- function(root, property) {
    onto <- tolower(get_ontologies(root))
    ont_ob <- rols::olsOntology(onto)
    root_term <- rols::olsTerm(ont_ob, root)

    ## Respect the dictionary's traversal property. Default to descendants when
    ## the property is missing (the common case for these fields).
    terms <- if (identical(property, "children")) {
        rols::children(root_term)
    } else {
        rols::descendants(root_term)
    }

    ids    <- rols::termId(terms)
    labels <- rols::termLabel(terms)
    syns   <- rols::termSynonym(terms)  # list, one character vector per term

    rows <- list()
    for (i in seq_along(ids)) {
        lab <- unname(labels[i])
        if (is.na(lab) || !nzchar(lab)) next
        term_syns <- syns[[i]]
        term_syns <- term_syns[!is.na(term_syns) & nzchar(term_syns)]
        ## Preferred-label-only row.
        rows[[length(rows) + 1L]] <- data.frame(
            term_id = unname(ids[i]), label = lab, synonym = "",
            stringsAsFactors = FALSE
        )
        ## One row per synonym.
        for (s in term_syns) {
            rows[[length(rows) + 1L]] <- data.frame(
                term_id = unname(ids[i]), label = lab, synonym = s,
                stringsAsFactors = FALSE
            )
        }
    }
    if (length(rows) == 0) {
        return(data.frame(term_id = character(), label = character(),
                          synonym = character(), stringsAsFactors = FALSE))
    }
    do.call(rbind, rows)
}

## Collect (term_id, label, synonyms) for a SINGLE term (no descendants). Used
## for static.enum entries: a handful of explicitly-allowed terms (e.g. Healthy)
## that are not descendants of the dynamic root.
collect_term <- function(id) {
    onto <- tolower(get_ontologies(id))
    term <- rols::olsTerm(rols::olsOntology(onto), id)
    lab <- unname(rols::termLabel(term))
    if (length(lab) == 0 || is.na(lab) || !nzchar(lab)) {
        return(data.frame(term_id = character(), label = character(),
                          synonym = character(), stringsAsFactors = FALSE))
    }
    term_syns <- rols::termSynonym(term)
    term_syns <- term_syns[!is.na(term_syns) & nzchar(term_syns)]
    rows <- list(data.frame(term_id = id, label = lab, synonym = "",
                            stringsAsFactors = FALSE))
    for (s in term_syns) {
        rows[[length(rows) + 1L]] <- data.frame(
            term_id = id, label = lab, synonym = s, stringsAsFactors = FALSE)
    }
    do.call(rbind, rows)
}

all_rows <- list()
for (r in seq_len(nrow(dyn))) {
    field <- dyn[["col.name"]][r]
    roots <- trimws(strsplit(dyn[["dynamic.enum"]][r], ";", fixed = TRUE)[[1]])
    roots <- roots[nzchar(roots)]
    property <- dyn[["dynamic.enum.property"]][r]
    if (is.na(property)) property <- "descendant"

    message("[", field, "] roots: ", paste(roots, collapse = ", "),
            " (", property, ")")
    field_rows <- list()
    for (root in roots) {
        rt <- tryCatch(collect_root(root, property), error = function(e) {
            warning("  failed for root ", root, ": ", conditionMessage(e))
            NULL
        })
        if (!is.null(rt) && nrow(rt) > 0) field_rows[[length(field_rows) + 1L]] <- rt
    }

    ## Also resolve any static.enum terms (exact terms, not descendants) and add
    ## them to this field's allowed set.
    static_ids <- dyn[["static.enum"]][r]
    if (!is.na(static_ids) && nzchar(static_ids)) {
        static_ids <- trimws(strsplit(static_ids, "|", fixed = TRUE)[[1]])
        static_ids <- static_ids[nzchar(static_ids)]
        for (sid in static_ids) {
            st <- tryCatch(collect_term(sid), error = function(e) {
                warning("  failed for static term ", sid, ": ",
                        conditionMessage(e))
                NULL
            })
            if (!is.null(st) && nrow(st) > 0) {
                message("  + static term ", sid, " -> ", st$label[1])
                field_rows[[length(field_rows) + 1L]] <- st
            }
        }
    }

    if (length(field_rows) == 0) next
    tab <- do.call(rbind, field_rows)
    tab <- unique(tab)
    tab <- cbind(field = field, tab, stringsAsFactors = FALSE)
    message("  -> ", nrow(tab), " rows (", length(unique(tab$label)), " labels)")
    all_rows[[length(all_rows) + 1L]] <- tab
}

result <- do.call(rbind, all_rows)
result <- result[, c("field", "term_id", "label", "synonym")]
result <- unique(result)

## Build the processed lookup structure consumed by
## .load_bundled_ontology_terms() / .validate_dynamic_enum() and serialize it as
## a compressed .rds. The flat table can be ~700k rows / tens of MB for broad
## ontology roots (e.g. disease, body_site_details), so we ship the compact
## per-field lookup (labels + synonym->label) rather than the raw CSV.
split_tabs <- split(result, result$field)
ontology_terms <- lapply(split_tabs, function(ft) {
    labels <- unique(ft$label)
    syn_rows <- ft[!is.na(ft$synonym) & nzchar(ft$synonym), , drop = FALSE]
    # A synonym that is itself a preferred label must not shadow it.
    syn_rows <- syn_rows[!syn_rows$synonym %in% labels, , drop = FALSE]
    synonym_lookup <- stats::setNames(syn_rows$label, syn_rows$synonym)
    # Keep the first mapping when a synonym points at multiple labels.
    synonym_lookup <- synonym_lookup[!duplicated(names(synonym_lookup))]
    list(labels = labels, synonym_lookup = synonym_lookup)
})

dir.create(dirname(out_path), showWarnings = FALSE, recursive = TRUE)
saveRDS(ontology_terms, out_path, compress = "xz")
message("Wrote lookup for ", length(ontology_terms), " fields (",
        nrow(result), " term/synonym rows) to: ", out_path)
