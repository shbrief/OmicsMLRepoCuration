% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mapNodes.R
\name{.groupRoots}
\alias{.groupRoots}
\title{Combines dataframe network representations that have the same roots}
\usage{
.groupRoots(nets)
}
\arguments{
\item{nets}{List of dataframes each containing a symbolic edge list of a
directed network in the first two columns. Edges are directed from the first
column to the second column. Additional columns are considered as edge
attributes.}
}
\value{
List of grouped dataframe network representations.
}
\description{
Combines dataframe network representations that have the same roots
}
\examples{
nets <- list(`NCIT:C94631` = structure(list(from = c("NCIT:C43431",
"NCIT:C16203", "NCIT:C25218", "NCIT:C49236", "NCIT:C15986", "NCIT:C15511",
"NCIT:C16119"), to = c("NCIT:C16203", "NCIT:C25218", "NCIT:C49236",
"NCIT:C15986", "NCIT:C15511", "NCIT:C16119", "NCIT:C94631")),
class = "data.frame", row.names = c(NA, -7L)),
`NCIT:C93322` = structure(list(from = c("NCIT:C43431", "NCIT:C16203",
"NCIT:C25218", "NCIT:C67022"), to = c("NCIT:C16203", "NCIT:C25218",
"NCIT:C67022", "NCIT:C93322")), class = "data.frame", row.names = c(NA, -4L)))

# .groupRoots(nets)

}
