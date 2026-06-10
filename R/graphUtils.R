#' Transforms rols tree representation into igraph-compatible dataframe network
#' representation
#' 
#' @importFrom dplyr rowwise mutate select rename filter
#' @importFrom plyr mapvalues
#' 
#' @param tree_frame rols JSON tree in dataframe format as created by
#' jsonlite::fromJSON.
#' 
#' @return Dataframe containing a symbolic edge list of a directed network in
#' the first two columns. Edges are directed from the first column to the second
#' column. Additional columns are considered as edge attributes.
#' 
#' @keywords internal
#'
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' tree_frame <- read.csv(file.path(dir, "sample_treeframe.csv"))
#'
#' # .createNetwork(tree_frame = tree_frame)
#'
.createNetwork <- function(tree_frame) {
    
    ## Create mapping between ontology IDs and tree IDs
    map <- tree_frame %>%
        rowwise() %>%
        mutate(term = unlist(strsplit(iri, split = "/"))[5]) %>%
        mutate(term = gsub("_", ":", term)) %>%
        select(id, term)
    
    ## Use mapping to build net
    net <- tree_frame %>%
        select(parent, id) %>%
        rename(from = parent,
               to = id) %>%
        filter(from != "#") %>%
        mutate(from = plyr::mapvalues(from, map$id, map$term, warn_missing = FALSE)) %>%
        mutate(to = plyr::mapvalues(to, map$id, map$term, warn_missing = FALSE))
    return(net)
}

#' Combines dataframe network representations that have the same roots
#' 
#' @param nets List of dataframes each containing a symbolic edge list of a
#' directed network in the first two columns. Edges are directed from the first
#' column to the second column. Additional columns are considered as edge
#' attributes.
#' 
#' @return List of grouped dataframe network representations.
#' 
#' @keywords internal
#'
#' @examples
#' nets <- list(`NCIT:C94631` = structure(list(from = c("NCIT:C43431",
#' "NCIT:C16203", "NCIT:C25218", "NCIT:C49236", "NCIT:C15986", "NCIT:C15511",
#' "NCIT:C16119"), to = c("NCIT:C16203", "NCIT:C25218", "NCIT:C49236",
#' "NCIT:C15986", "NCIT:C15511", "NCIT:C16119", "NCIT:C94631")),
#' class = "data.frame", row.names = c(NA, -7L)),
#' `NCIT:C93322` = structure(list(from = c("NCIT:C43431", "NCIT:C16203",
#' "NCIT:C25218", "NCIT:C67022"), to = c("NCIT:C16203", "NCIT:C25218",
#' "NCIT:C67022", "NCIT:C93322")), class = "data.frame", row.names = c(NA, -4L)))
#'
#' # .groupRoots(nets)
#'
.groupRoots <- function(nets) {
    
    ## Get roots for each net as a factor and use to group
    fac <- as.factor(unlist(lapply(nets, function(x) x[1, 1])))
    groups <- split(nets, fac)
    return(groups)
}

#' Retrieves lowest common ancestor or group of ancestors for a given set of
#' nodes within an igraph network object
#' 
#' @importFrom igraph dfs degree subgraph distances
#' 
#' @param graph An igraph network object.
#' @param vex Character vector of term ids to find lowest common ancestor(s) for.
#' 
#' @return Character vector of lowest common ancestor(s).
#' 
#' @keywords internal
#'
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#'
#' graph <- igraph::graph_from_data_frame(d = net,
#' vertices = unique(unlist(net)))
#'
#' vex <- c("NCIT:C270", "NCIT:C93038")
#'
#' # .LCA(graph = graph, vex = vex)
#'
.LCA <- function(graph, vex) {
    
    ## Get ancestors of each given term
    ancs <- lapply(vex, function(x) dfs(graph,
                                        x,
                                        mode = "in",
                                        unreachable = FALSE)$order)
    
    ## Find intersecting ancestors as LCA candidates
    common_ancs <- Reduce(intersect, ancs)
    
    ## Compare candidate degrees and distances from root to find LCA(s)
    odegs <- degree(subgraph(graph, common_ancs), mode = "out")
    leaves <- names(odegs)[odegs == 0]
    idegs <- degree(graph, mode = "in")
    root <- names(idegs)[idegs == 0]
    dists <- suppressWarnings(distances(graph,
                                        v = leaves,
                                        to = root,
                                        algorithm = "unweighted"))
    dist_sums <- rowSums(dists)
    lcas <- names(which.max(dist_sums))
    return(lcas)
}

#' Selects representative nodes for a cluster when LCAs are not available
#' 
#' @importFrom igraph degree subgraph dfs
#' 
#' @param graph An igraph network object.
#' @param vex Character vector of term ids that make up a single cluster.
#' @param ovex Character vector of original term ids present in the cluster.
#' 
#' @return Character vector of representative term ids.
#' 
#' @keywords internal
#'
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#'
#' graph <- igraph::graph_from_data_frame(d = net,
#' vertices = unique(unlist(net)))
#'
#' vex <- c("NCIT:C78274", "NCIT:C270", "NCIT:C783", "NCIT:C93038",
#' "NCIT:C47793", "NCIT:C247", "NCIT:C62002")
#' ovex <- c("NCIT:C270", "NCIT:C93038")
#'
#' # .bestRoots(graph = graph, vex = vex, ovex = ovex)
#'
.bestRoots <- function(graph, vex, ovex) {
    
    ## Compare degrees of all cluster nodes to find roots
    odegs <- degree(subgraph(graph, vex), mode = "out")
    idegs <- degree(subgraph(graph, vex), mode = "in")
    oordered <- odegs[order(odegs, decreasing = TRUE)]
    iordered <- idegs[names(oordered)]
    
    roots <- names(iordered)[iordered == 0]
    
    ## Retrieve all descendants of roots
    children <- lapply(roots, function(x) names(dfs(graph,
                                                    x,
                                                    mode = "out",
                                                    unreachable = FALSE)$order))
    
    ## Move through roots until all original terms are covered
    i <- 0
    best_roots <- c()
    while(length(ovex) > 0 & i < length(roots)) {
        i <- i + 1
        cur_root <- children[[i]]
        ncov <- sum(ovex %in% cur_root)
        
        if (ncov > 1) {
            best_roots <- c(best_roots, roots[i])
        } else if (ncov == 1) {
            best_roots <- c(best_roots, ovex[ovex %in% cur_root])
        }
        
        ovex <- ovex[!ovex %in% cur_root]
    }
    
    best_roots <- c(best_roots, ovex)
    return(best_roots)
}

#' Removes nodes that are descendants of already chosen nodes
#' 
#' @importFrom igraph dfs
#' 
#' @param graph An igraph network object.
#' @param nodes Character vector; ids of nodes to check.
#' 
#' @return Character vector; consolidated list of ids.
#' 
#' @keywords internal
#'
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#'
#' graph <- igraph::graph_from_data_frame(d = net,
#' vertices = unique(unlist(net)))
#'
#' nodes <- c("NCIT:C78274", "NCIT:C29711", "NCIT:C254", "NCIT:C29249",
#' "NCIT:C47639", "NCIT:C78272")
#'
#' # .consolidateNodes(graph = graph, nodes = nodes)
#'
.consolidateNodes <- function(graph, nodes) {
    
    ## Retrieve all ancestors of given nodes
    ancs <- lapply(nodes, function(x) names(dfs(graph,
                                              x,
                                              mode = "in",
                                              unreachable = FALSE)$order[-1]))
    
    ## Remove given node if another given node is an ancestor
    child <- unlist(lapply(ancs, function(x) any(x %in% nodes)))
    fnodes <- nodes[!child]
    return(fnodes)
}

#' Retrieves all original terms covered by a given node within an igraph network
#' object.
#' 
#' @importFrom igraph dfs
#' 
#' @param graph An igraph network object.
#' @param node Character string; id of node to check descendants of.
#' @param original_terms Character vector; ids of original terms to check
#' coverage of.
#' 
#' @return Character vector of original terms covered by "node."
#' 
#' @keywords internal
#'
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#'
#' graph <- igraph::graph_from_data_frame(d = net,
#' vertices = unique(unlist(net)))
#'
#' original_terms <- c("NCIT:C29711", "NCIT:C270", "NCIT:C250", "NCIT:C47639",
#' "NCIT:C29249", "NCIT:C983", "NCIT:C247", "NCIT:C47384", "NCIT:C62002",
#' "NCIT:C281")
#'
#' # .getDescs(graph = graph, node = "NCIT:C78274",
#' # original_terms = original_terms)
#'
.getDescs <- function(graph, node, original_terms) {
    
    ## Retrieve all descendants of given node
    children <- names(dfs(graph,
                          node,
                          mode = "out",
                          unreachable = FALSE)$order)
    
    ## Return all original terms that are present in "children"
    odescs <- children[children %in% original_terms]
    return(odescs)
}

#' Creates igraph network object from a dataframe network representation
#' 
#' @importFrom igraph graph_from_data_frame
#' @importFrom dplyr mutate case_when
#' 
#' @param net Dataframe containing a symbolic edge list of a directed network in
#' the first two columns. Edges are directed from the first column to the second
#' column. Additional columns are considered as edge attributes.
#' @param original_terms A character vector of ontology terms to ensure
#' coverage of.
#' 
#' @return An igraph network object with vertex attribute "type." "type" values
#' include "root," "original," and "bridge."
#' 
#' @keywords internal
#'
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#'
#' original_terms <- c("NCIT:C29711", "NCIT:C270", "NCIT:C250", "NCIT:C47639",
#' "NCIT:C29249", "NCIT:C983", "NCIT:C247", "NCIT:C47384", "NCIT:C62002",
#' "NCIT:C281")
#'
#' # .createGraph(net = net, original_terms = original_terms)
#'
.createGraph <- function(net, original_terms) {

    ## Get different types of nodes
    vex <- unique(unlist(net))
    ovex <- original_terms
    root <- vex[!vex %in% net[,2]]
    
    ## Prepare edge dataframe with "weight" attribute
    eframe <- net %>%
        mutate(weight = 1)
    
    ## Prepare vertex dataframe with "type" attribute
    vframe <- data.frame(vex = vex,
                         type = NA)
    vframe <- vframe %>%
        mutate(type = case_when(vex %in% root ~ "root",
                                vex %in% ovex ~ "original",
                                .default = "bridge"))
    
    ## Return igraph network object
    network <- graph_from_data_frame(d = eframe, vertices = vframe)
    return(network)
}

#' Detects nodes that cover greater than a certain percentage of the network
#' 
#' @importFrom igraph V dfs
#' 
#' @param netgraph igraph network object of ontology term IDs.
#' @param max_nodes Integer to indicate number of covered nodes that makes a
#' node "high-traffic."
#' 
#' @return A character vector of high-traffic node ids.
#' 
#' @keywords internal
#'
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#'
#' netgraph <- igraph::graph_from_data_frame(d = net,
#' vertices = unique(unlist(net)))
#'
#' # .busyNodes(netgraph = netgraph, max_nodes = 20)
#'
.busyNodes <- function(netgraph, max_nodes) {
    
    ## Use descendant number cutoff to identify high-traffic nodes
    dnums <- unlist(lapply(V(netgraph), function(x)
        length(dfs(netgraph, x, mode = "out", unreachable = FALSE)$order)))
    remnodes <- names(which(dnums > max_nodes))
    return(remnodes)
}


#' Selects representative nodes for a network of ontology terms using igraph
#' clustering functionality
#' 
#' @importFrom igraph delete_vertices cluster_fast_greedy as.undirected communities
#' 
#' @param netgraph igraph network object of ontology term IDs.
#' @param original_terms A character vector of ontology term IDs to ensure
#' coverage of.
#' @param max_nodes Integer to indicate number of covered nodes that makes a node
#' "high-traffic."
#' 
#' @return A character vector of representative nodes.
#' 
#' @keywords internal
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
#' # .clusterNodes(netgraph = netgraph, original_terms = original_terms,
#' # max_nodes = 20)
#'
.clusterNodes <- function(netgraph, original_terms, max_nodes) {
    
    ## Use descendant number cutoff to remove high-traffic nodes
    bnodes <- .busyNodes(netgraph, max_nodes)
    remnodes <- bnodes[!bnodes %in% original_terms]
    remnet <- delete_vertices(netgraph, remnodes)
    
    ## Cluster network
    remclust <- cluster_fast_greedy(as.undirected(remnet))
    coms <- communities(remclust)
    original_coms <- lapply(coms, function(x) x[x %in% original_terms])
    
    emptyids <- which(lengths(original_coms) == 0)
    coms[emptyids] <- NULL
    original_coms[emptyids] <- NULL
    
    ## Get representative nodes for each cluster
    com_lcas <- lapply(original_coms, function(x) .LCA(netgraph, x))
    
    remids <- which(unname(unlist(lapply(com_lcas,
                                         function(x) any(x %in% remnodes)))))
    rem_coms <- coms[remids]
    rem_ocoms <- original_coms[remids]
    best_coms <- mapply(function(c, o) .bestRoots(netgraph, c, o),
                        rem_coms,
                        rem_ocoms,
                        SIMPLIFY = FALSE)
    com_lcas[remids] <- best_coms
    
    ## Consolidate redundant nodes
    nodes <- unique(unname(unlist(com_lcas)))
    cnodes <- .consolidateNodes(netgraph, nodes)
    return(cnodes)
}

