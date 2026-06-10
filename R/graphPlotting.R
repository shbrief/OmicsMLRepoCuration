#' Vertex color palette shared by the network plotting functions
#' @keywords internal
.netColors <- function() {
    c("root" = "blue", "bridge" = "orange",
      "original" = "green", "picked" = "purple")
}

#' Legend labels shared by the network plotting functions
#' @keywords internal
.netLabels <- function() {
    c("Root", "Intermediate term", "Original term", "Picked term")
}

#' Draw the standard node-type legend for the network plots
#' @keywords internal
.drawNetLegend <- function(legend_colors, legend_labels) {
    .drawNetLegend(legend_colors, legend_labels)
}

#' Plot a network graph with specific vertices highlighted by vertex color and a
#' a smoothed polygon
#' 
#' @importFrom igraph V simplify
#' 
#' @param net An igraph network object with a "type" vertex attribute;
#' "type" = "root", "bridge", "original", or "picked"
#' @param mark_nodes Character vector of vertices to highlight
#' @param mark_color Character; color to highlight vertices
#' @param mark_label Character; legend label for highlighted vertices; defaults
#' to "Marked node"
#' @param layout An igraph layout object or layout function
#' 
#' @return An igraph plot
#' 
#' @export
#' 
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#' 
#' netgraph <- igraph::graph_from_data_frame(d = net,
#' vertices = unique(unlist(net)))
#' original_terms <- c("NCIT:C29711", "NCIT:C270", "NCIT:C250", "NCIT:C47639",
#' "NCIT:C29249", "NCIT:C983", "NCIT:C247", "NCIT:C47384", "NCIT:C62002",
#' "NCIT:C281")
#' 
#' V(netgraph)$type <- "bridge"
#' V(netgraph)[original_terms]$type <- "original"
#' V(netgraph)["NCIT:C1908"]$type <- "root"
#' V(netgraph)["NCIT:C78272"]$type <- "picked"
#' 
#' marked <- c("NCIT:C1909", "NCIT:C1908", "NCIT:C78276", "NCIT:C471",
#' "NCIT:C78274", "NCIT:C93038")
#' 
#' # markNet(net = netgraph, mark_nodes = marked)
#' 
markNet <- function(net, mark_nodes, mark_color = "white",
                    mark_label = "Marked node", layout = layout_with_fr) {
    colors <- .netColors()
    labels <- .netLabels()
    V(net)$color <- colors[V(net)$type]
    V(net)[mark_nodes]$color <- mark_color
    legend_colors <- c(mark_color,
                       unname(colors[which(colors %in% V(net)$color)]))
    legend_labels <- c(mark_label,
                       labels[which(colors %in% V(net)$color)])
    
    plot(simplify(net, remove.multiple = TRUE),
         mark.groups = list(mark_nodes),
         mark.col = "lightblue",
         mark.border = NA,
         layout = layout,
         edge.arrow.size = .3,
         vertex.size = 3,
         vertex.label = NA)
    .drawNetLegend(legend_colors, legend_labels)
}

#' Plot a network graph with vertices colored by type
#' 
#' @importFrom igraph V simplify
#' 
#' @param net An igraph network object with a "type" vertex attribute;
#' "type" = "root", "bridge", "original", or "picked"
#' @param layout An igraph layout object or layout function
#' 
#' @return An igraph plot
#' 
#' @export
#' 
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#' 
#' netgraph <- igraph::graph_from_data_frame(d = net,
#' vertices = unique(unlist(net)))
#' original_terms <- c("NCIT:C29711", "NCIT:C270", "NCIT:C250", "NCIT:C47639",
#' "NCIT:C29249", "NCIT:C983", "NCIT:C247", "NCIT:C47384", "NCIT:C62002",
#' "NCIT:C281")
#' 
#' V(netgraph)$type <- "bridge"
#' V(netgraph)[original_terms]$type <- "original"
#' V(netgraph)["NCIT:C1908"]$type <- "root"
#' V(netgraph)["NCIT:C78272"]$type <- "picked"
#' 
#' # plotNet(netgraph)
#' 
plotNet <- function(net, layout = layout_with_fr) {
    colors <- .netColors()
    labels <- .netLabels()
    V(net)$color <- colors[V(net)$type]
    legend_colors <- unname(colors[which(colors %in% V(net)$color)])
    legend_labels <- labels[which(colors %in% V(net)$color)]
    
    plot(simplify(net, remove.multiple = TRUE),
         layout = layout,
         edge.arrow.size = .3,
         vertex.size = 3,
         vertex.label = NA)
    .drawNetLegend(legend_colors, legend_labels)
}

#' Plot a network graph with multiple communities/clusters highlighted
#' 
#' @importFrom igraph V simplify
#' 
#' @param net An igraph network object with a "type" vertex attribute;
#' "type" = "root", "bridge", "original", or "picked"
#' @param communities List of character vectors representing groups to mark; as
#' output by igraph clustering functions
#' @param layout An igraph layout object or layout function
#' 
#' @return An igraph plot
#' 
#' @export
#' 
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#' 
#' netgraph <- igraph::graph_from_data_frame(d = net,
#' vertices = unique(unlist(net)))
#' original_terms <- c("NCIT:C29711", "NCIT:C270", "NCIT:C250", "NCIT:C47639",
#' "NCIT:C29249", "NCIT:C983", "NCIT:C247", "NCIT:C47384", "NCIT:C62002",
#' "NCIT:C281")
#' 
#' V(netgraph)$type <- "bridge"
#' V(netgraph)[original_terms]$type <- "original"
#' V(netgraph)["NCIT:C1908"]$type <- "root"
#' V(netgraph)["NCIT:C78272"]$type <- "picked"
#' 
#' clusters <- list(c("NCIT:C78276", "NCIT:C471", "NCIT:C2846", "NCIT:C983",
#' "NCIT:C29711"), c("NCIT:C47384", "NCIT:C250", "NCIT:C276", "NCIT:C281",
#' "NCIT:C254"))
#' 
#' # plotClusters(net = netgraph, communities = clusters)
#' 
plotClusters <- function(net, communities, layout = layout_with_fr) {
    colors <- .netColors()
    labels <- .netLabels()
    V(net)$color <- colors[V(net)$type]
    legend_colors <- unname(colors[which(colors %in% V(net)$color)])
    legend_labels <- labels[which(colors %in% V(net)$color)]
    
    plot(simplify(net, remove.multiple = TRUE),
         layout = layout,
         mark.groups = communities,
         edge.arrow.size = .3,
         vertex.size = 3,
         vertex.label = NA)
    .drawNetLegend(legend_colors, legend_labels)
}

