#' Mapping terms to the same ontology
#'
#' This function maps input ontology terms to a identical/similar terms in
#' the target ontology through Ontology Xref Service (OxO) API.
#' (https://www.ebi.ac.uk/spot/oxo/)
#'
#' @importFrom httr2 request req_headers resp_body_json req_perform
#'
#' @param term_ids A character vector of term ids to retrieve mappings for
#' @param target_ontology Optional character (1). The target ontology library to
#' map the `term_ids` to.
#' @param mapping_distance Optional. Mapping distance as an integer, 1
#' (default), 2, or 3.
#'
#' @return A list of of data frames with mapping results for each input term
#'
#' @examples
#' term_ids <- c("NCIT:C2855", "EFO:0000228", "NCIT:C35025", "HP:0003003",
#'               "HP:0001824", "MONDO:0010200", "NCIT:C122328")
#' oxoMap(term_ids, "NCIT")
#'
oxoMap <- function(term_ids, target_ontology = "none", mapping_distance = 1) {
  # Validate input
  stopifnot(is.character(term_ids),
            is.character(target_ontology),
            is.numeric(mapping_distance),
            mapping_distance %in% c(1, 2, 3))

  # Prepare inputs
  term_ids <- as.list(term_ids)
  target_ontology <- as.list(target_ontology)

  # Prepare request
  body_json <- list(ids = term_ids,
                    inputSource = NULL,
                    mappingTarget = target_ontology,
                    distance = mapping_distance)
  
  if (target_ontology == "none") {
      body_json["mappingTarget"] <- NULL
  }
  
  req <- request("https://www.ebi.ac.uk/spot/oxo/api/search?size=200") %>%
    req_headers("Content-Type" = "application/json",
                "Accept" = "application/json") %>%
    req_body_json(body_json)

  # Perform request
  resp <- req_perform(req)

  # Parse response
  resp_json <- resp_body_json(resp)
  resp_list <- lapply(resp_json$`_embedded`$searchResults,
                      function(x) as.data.frame(do.call(rbind,
                                                        x$mappingResponseList)))
  names(resp_list) <- term_ids

  # Return as list of data frames
  return(resp_list)
}
