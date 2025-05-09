% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mapNodes.R
\name{.LCA}
\alias{.LCA}
\title{Retrieves lowest common ancestor or group of ancestors for a given set of
nodes within an igraph network object}
\usage{
.LCA(graph, vex)
}
\arguments{
\item{graph}{An igraph network object.}

\item{vex}{Character vector of term ids to find lowest common ancestor(s) for.}
}
\value{
Character vector of lowest common ancestor(s).
}
\description{
Retrieves lowest common ancestor or group of ancestors for a given set of
nodes within an igraph network object
}
\examples{
dir <- system.file("extdata", package = "OmicsMLRepoCuration")
net <- read.csv(file.path(dir, "sample_net.csv"))

graph <- igraph::graph_from_data_frame(d = net,
vertices = unique(unlist(net)))

vex <- c("NCIT:C270", "NCIT:C93038")

# .LCA(graph = graph, vex = vex)

}
