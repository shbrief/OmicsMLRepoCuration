% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/mapNodes.R
\name{.consolidateNodes}
\alias{.consolidateNodes}
\title{Removes nodes that are descendants of already chosen nodes}
\usage{
.consolidateNodes(graph, nodes)
}
\arguments{
\item{graph}{An igraph network object.}

\item{nodes}{Character vector; ids of nodes to check.}
}
\value{
Character vector; consolidated list of ids.
}
\description{
Removes nodes that are descendants of already chosen nodes
}
\examples{
dir <- system.file("extdata", package = "OmicsMLRepoCuration")
net <- read.csv(file.path(dir, "sample_net.csv"))

graph <- igraph::graph_from_data_frame(d = net,
vertices = unique(unlist(net)))

nodes <- c("NCIT:C78274", "NCIT:C29711", "NCIT:C254", "NCIT:C29249",
"NCIT:C47639", "NCIT:C78272")

# .consolidateNodes(graph = graph, nodes = nodes)

}
