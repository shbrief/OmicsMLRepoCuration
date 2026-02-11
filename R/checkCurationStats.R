#' Calculate the completeness of metadata
#'
#' @importFrom dplyr pull
#' @importFrom utils read.csv
#' @importFrom stringr str_squish str_replace
#'
#'
#' @param fields_list A character vector with the original columns/fields names.
#' Multiple values should be separated by semi-colon(;).
#' @param check A character(1) specifying a status of requested fields.
#' Currently available values are \code{completeness} (default) and
#' \code{unique}
#' @param DB A table you want to check the completeness or uniqueness of
#' each attributes/columns. The table can be provided in two ways: 1) a
#' character(1) specifying a database/dataset you want to check the
#' completeness of fields selected through \code{fields} argument. Or
#' you can 2) directly provide the metadata table (recommended for a
#' large metadata such as cBioPortal). Currently, metadata from
#' curatedMetagenomicData ("\code{cMD}") is only supported.
#' @param show_available_fields Default is \code{FALSE}. If is it set to
#' \code{TRUE}, names of all the available fields/columns will be returned as
#' a character vector.
#'
#' @return A character vector with the same length as that of \code{fields_list}
#' representing the percentage completeness of the requested fields.
#'
#' @note
#' For cBioPortalData metadata, there are many column names with space and two
#' with `.` (`PATHWAY_ACTIVITY_JAK.STAT` and `RADIATION_DOSE_PELVIC_NODES_PRIMARY_TUMOR.`).
#' To handle these, this function manually add back two with `.`.
#'
#' @examples
#' checkCurationStats(c("curated_age_years", "curated_age_group"), DB = "cMD")
#' checkCurationStats(c("curated_age_years;curated_age_group"), DB = "cMD")
#'
#'
#' @export
checkCurationStats <- function(
        fields_list,
        check = "completeness",
        DB = NULL,
        show_available_fields = FALSE) {

    if (is.null(DB)) {
        stop("Provide the database to `DB` argument.")
    } else if (is.data.frame(DB)) {
        tb <- DB
    } else if (DB == "cMD") {
        dir <- system.file("extdata", package = "OmicsMLRepoCuration")
        fpath <- file.path(dir, "cMD_curated_metadata_all.csv")
        tb <- read.csv(fpath)
    }

    if (isTRUE(show_available_fields)) { # Place this early will be more efficient
        allCols <- colnames(tb)
        return(allCols)
    }

    res_all <- vector(mode = "character", length = length(fields_list))
    univ <- nrow(tb)

    for (i in seq_along(fields_list)) {
        fields <- gsub("\\.", " ", fields_list[i]) %>% # replace `.` introduced to space
            strsplit(., split = ";") %>%
            unlist %>%
            stringr::str_squish(.) # remove unintended space

        ## Manually fix the mal-formed original column names
        fields <- stringr::str_replace(fields, "PATHWAY_ACTIVITY_JAK STAT", "PATHWAY_ACTIVITY_JAK.STAT") %>%
            stringr::str_replace(., "RADIATION_DOSE_PELVIC_NODES_PRIMARY_TUMOR", "RADIATION_DOSE_PELVIC_NODES_PRIMARY_TUMOR.")

        ## source fields that are derivative, thus not in the original table
        if (exists("missing_cols")) {rm(missing_cols)} # remove the variable
        if (!all(fields %in% colnames(tb)) & any(!is.na(fields))) {
            missing_cols <- which(!fields %in% colnames(tb))
            msg <- paste(fields[missing_cols], "column does not exist.")
            fields <- fields[-missing_cols] # remove column(s) not in the source table
        }

        if (any(is.na(fields))) {
            res <- NA
        } else {
            res <- vector(mode = "numeric", length = length(fields))
            if (check == "completeness") {
                for (j in seq_along(fields)) {
                    p <- round(sum(!is.na(tb[,fields[j]]))/univ*100)
                    res[j] <- p
                }
            } else if (check == "unique") {
                for (j in seq_along(fields)) {
                    unique_vect <- unique(tb[, fields[j]])

                    if (is.data.frame(unique_vect)) {
                        unique_vect <- pull(unique_vect)
                    }
                    if (!is.character(unique_vect)) {
                        unique_vect <- as.character(unique_vect)
                    }

                    unique_vect <- unique_vect |>
                        strsplit(split = "<;>") |> unlist() |>
                        strsplit(split = ";") |> unlist() |>
                        unique()

                    p <- length(unlist(unique_vect))
                    res[j] <- p
                }
            }
        }

        ## Put the missing columns completeness/num_unique_vals as 0
        if (exists("missing_cols")) {
            res[length(res)+1] <- "NA"
        }
        res_all[i] <- paste0(res, collapse = ";")
    }

    return(res_all)
}
