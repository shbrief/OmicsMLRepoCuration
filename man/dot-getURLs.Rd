% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mapNodes.R
\name{.getURLs}
\alias{.getURLs}
\title{Extract urls for JSON trees from rols Term object}
\usage{
.getURLs(onto, terms)
}
\arguments{
\item{onto}{A character vector. Name(s) of ontologies that terms are from.}

\item{terms}{A character vector of ontology term IDs.}
}
\value{
A named list. Names of elements are original nodes (`terms`).
Each element is a character link to a JSON tree or the string "no tree".
}
\description{
Extract urls for JSON trees from rols Term object
}
\examples{
term_ids <- c("NCIT:C2855", "NCIT:C35025", "NCIT:C122328")
# .getURLs("NCIT", term_ids)
}
