library(rols)
library(tidyverse)
library(jsonlite)
library(igraph)

#' Extract urls for JSON trees from rols Term object
#'
#' @importFrom rols Ontology Term
#'
#' @param onto A character vector. Name(s) of ontologies that terms are from.
#' @param terms A character vector of ontology term IDs.
#'
#' @return A named list. Names of elements are original nodes (`terms`). 
#' Each element is a character link to a JSON tree or the string "no tree".
#' 
#' @examples
#' term_ids <- c("NCIT:C2855", "NCIT:C35025", "NCIT:C122328")
#' .getURLs("NCIT", term_ids)
#'
.getURLs <- function(onto, terms) {
    
    ## Load ontology
    ontob <- Ontology(onto)
    
    ## Get unique terms
    terms <- unique(terms)
    
    ## Initialize list to store retrieved links
    all_trees <- list()
    
    ## Loop through supplied terms
    for (i in 1:length(terms)) {
        print(paste0("Getting url for ", terms[i]))
        
        tryCatch({
            ## Get Term object and extract JSON tree link
            cur_trm <- Term(ontob, terms[i])
            jstree <- cur_trm@links$jstree$href
            
        }, error = function(e) {
            print(e)
            print("Unable to access tree, proceeding to next term")
            jstree <<- "no tree"
        })
        
        ## Add link to list, named by term id
        all_trees <- c(all_trees, jstree)
        names(all_trees)[i] <- terms[i]
    }
    return(all_trees)
}

#'
createNetwork <- function(tree_frame) {
    
    ## Create mapping between term IDs and 
    map <- tree_frame %>%
        rowwise() %>%
        mutate(term = unlist(strsplit(iri, split = "/"))[5]) %>%
        mutate(term = gsub("_", ":", term)) %>%
        select(id, term)
    
    net <- tree_frame %>%
        select(parent, id) %>%
        rename(from = parent,
               to = id) %>%
        filter(from != "#") %>%
        mutate(from = plyr::mapvalues(from, map$id, map$term, warn_missing = FALSE)) %>%
        mutate(to = plyr::mapvalues(to, map$id, map$term, warn_missing = FALSE))
    return(net)
}

#'
groupRoots <- function(nets) {
    fac <- as.factor(unlist(lapply(nets, function(x) x$from[1])))
    groups <- split(nets, fac)
    return(groups)
}

#'
LCA <- function(graph, vex) {
    ancs <- lapply(vex, function(x) dfs(graph,
                                        x,
                                        mode = "in",
                                        unreachable = FALSE)$order)
    common_ancs <- Reduce(intersect, ancs)
    odegs <- degree(subgraph(graph, common_ancs), mode = "out")
    leaves <- names(odegs)[odegs == 0]
    idegs <- degree(graph, mode = "in")
    root <- names(idegs)[idegs == 0]
    dists <- suppressWarnings(distances(graph,
                                        v = leaves,
                                        to = root,
                                        algorithm = "unweighted"))
    lcas <- rownames(dists)[which(dists == max(dists))]
    return(lcas)
}

#'
bestRoots <- function(graph, vex, ovex) {
    odegs <- degree(subgraph(graph, vex), mode = "out")
    idegs <- degree(subgraph(graph, vex), mode = "in")
    oordered <- odegs[order(odegs, decreasing = TRUE)]
    iordered <- idegs[names(oordered)]
    
    roots <- names(iordered)[iordered == 0]
    
    children <- lapply(roots, function(x) names(dfs(graph,
                                                    x,
                                                    mode = "out",
                                                    unreachable = FALSE)$order[-1]))
    
    i <- 0
    while(length(ovex) > 0 & i < length(roots)) {
        i <- i + 1
        cur_root <- children[[i]]
        ovex <- ovex[!ovex %in% cur_root]
    }
    
    best_roots <- c(roots[1:i], ovex)
    return(best_roots)
}

#'
consolidateNodes <- function(graph, vex) {
    ancs <- lapply(vex, function(x) names(dfs(graph,
                                              x,
                                              mode = "in",
                                              unreachable = FALSE)$order[-1]))
    child <- unlist(lapply(ancs, function(x) any(x %in% vex)))
    nodes <- vex[!child]
    return(nodes)
}

#'
getDescs <- function(graph, node, ovex) {
    children <- names(dfs(graph,
                          node,
                          mode = "out",
                          unreachable = FALSE)$order)
    odescs <- children[children %in% ovex]
    return(odescs)
}

#'
createGraph <- function(net, original_terms) {
    vex <- unique(unlist(net))
    ovex <- original_terms
    root <- vex[!vex %in% net$to]
    
    eframe <- net %>%
        mutate(weight = 1)
    vframe <- data.frame(vex = vex,
                         type = NA)
    vframe <- vframe %>%
        mutate(type = case_when(vex == root ~ "root",
                                vex %in% ovex ~ "original",
                                .default = "bridge"))
    network <- graph_from_data_frame(d = eframe, vertices = vframe)
    return(network)
}

#' Selects representative notes for a network of ontology terms using igraph
#' clustering functionality
#' 
#' @importFrom igraph degree V delete_vertices cluster_fast_greedy as.undirected communities
#' 
#' @param netgraph igraph network object of ontology term IDs.
#' @param original_terms A character vector of ontology term IDs to ensure
#' coverage of.
#' @param cutoff Optional. Float to indicate percentage of network coverage that
#' makes a node "high-traffic." Defaults to 0.25.
#' 
#' @examples
#' dir <- system.file("extdata", package="OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#' 
#' netgraph <- igraph::graph_from_data_frame(d = net,
#' vertices = unique(unlist(net)))
#' original_terms <- c("NCIT:C29711", "NCIT:C270", "NCIT:C250", "NCIT:C47639",
#' "NCIT:C29249", "NCIT:C983", "NCIT:C247", "NCIT:C47384", "NCIT:C62002",
#' "NCIT:C281")
#' 
#' .clusterNodes(netgraph = netgraph, original_terms = original_terms)
#'
.clusterNodes <- function(netgraph, original_terms, cutoff = 0.25) {
    
    ## Use edge weight cutoff to remove high-traffic nodes    
    remnodes <- names(which(degree(netgraph, mode = "out")
                            > (cutoff * length(V(netgraph)))))
    remnet <- delete_vertices(netgraph, remnodes)
    
    ## Cluster network
    remclust <- cluster_fast_greedy(as.undirected(remnet))
    coms <- communities(remclust)
    original_coms <- lapply(coms, function(x) x[x %in% original_terms])
    
    emptyids <- which(lengths(original_coms) == 0)
    coms[emptyids] <- NULL
    original_coms[emptyids] <- NULL
    
    ## Get representative nodes for each cluster
    com_lcas <- lapply(original_coms, function(x) LCA(netgraph, x))
    
    remids <- which(unname(unlist(lapply(com_lcas,
                                         function(x) any(x %in% remnodes)))))
    rem_coms <- coms[remids]
    rem_ocoms <- original_coms[remids]
    best_coms <- mapply(function(c, o) bestRoots(netgraph, c, o),
                        rem_coms,
                        rem_ocoms,
                        SIMPLIFY = FALSE)
    com_lcas[remids] <- best_coms
    
    ## Consolidate redundant nodes
    nodes <- unique(unname(unlist(com_lcas)))
    cnodes <- consolidateNodes(netgraph, nodes)
    return(cnodes)
}

#' Retrieves ideal representative nodes for a vector of ontology term ids
#' 
#' @importFrom tidyverse distinct compact
#' @importFrom igraph V
#' 
#' @param ids Character vector of term ids.
#' 
#' @return A Dataframe of chosen nodes including information on number of 
#' original terms covered.
#' 
#' @examples
#' ids <- c("CHEBI:166822", "NCIT:C47639", "FOODON:03600010", "NCIT:C29249",
#' "NCIT:C983", "NCIT:C247", "NCIT:C47384", "NCIT:C62002", "NCIT:C250",
#' "NCIT:C270", "NCIT:C94631", "NCIT:C281", "NCIT:C29711", "NCIT:C270")
#' mapNodes(ids)
#' 
mapNodes <- function(ids, cutoff = 0.25) {
    
    ## Get ontology information from ids
    dbs <- unlist(lapply(ids, get_ontologies))
    map <- data.frame(id = ids,
                      db = dbs)
    map <- distinct(map)
    
    ## Split ids by ontology
    term_frames <- split(map, map$db)
    all_terms <- lapply(term_frames, function(x) x$id)
    
    ## Retrieve tree information
    tryCatch({
        json_urls <- compact(mapply(function(n, t) .getURLs(n, t),
                                    names(all_terms),
                                    all_terms,
                                    SIMPLIFY = FALSE))
        fails <- compact(lapply(json_urls, function(x) x[x == "no tree"]))
        good_urls <- compact(lapply(json_urls, function(x) x[x != "no tree"]))
        fail_names <- unlist(lapply(fails, names), use.names = FALSE)
        fail_list <- setNames(as.list(fail_names), fail_names)
        print(paste0("Retrieving ", sum(lengths(good_urls)), " trees"))
        tree_frames <- lapply(good_urls, function(x) lapply(x, fromJSON))
    }, error = function(e) {
        print(e)
    })
    
    ## Set up and group networks
    tree_nets <- lapply(tree_frames, function(x) lapply(x, createNetwork))
    tree_groups <- lapply(tree_nets, groupRoots)
    netnames <- unlist(lapply(tree_groups, names), use.names = FALSE)
    big_nets <- unlist(lapply(tree_groups, function(x) lapply(x, bind_rows)),
                       recursive = FALSE)
    names(big_nets) <- netnames
    grouped_terms <- lapply(big_nets, function(x) unique(unlist(x)))
    grouped_originals <- lapply(grouped_terms, function(x) x[x %in% ids])
    netgraphs <- mapply(function(n, o) createGraph(n, o),
                        big_nets, grouped_originals, SIMPLIFY = FALSE)
    
    ## Separate different-sized graphs
    ## for either LCA or cluster-based node selection
    single <- lengths(grouped_originals) == 1
    cutoffs <- unlist(lapply(netgraphs, function(x) length(V(x)) * cutoff))
    test_cuts <- mapply(function(n, c)
        length(names(which(degree(n, mode = "out") > c))), netgraphs, cutoffs,
        SIMPLIFY = FALSE)
    clust <- test_cuts != 0
    
    cluster_ids <- which(!single & clust)
    
    cluster_nets <- netgraphs[cluster_ids]
    lca_nets <- netgraphs[-cluster_ids]
    
    ## Select nodes for LCA-compatible graphs
    lca_nodes <- mapply(function(g, o) LCA(g, o),
                        netgraphs[-cluster_ids, drop = FALSE],
                        grouped_originals[-cluster_ids, drop = FALSE],
                        SIMPLIFY = FALSE)
    
    ## Select nodes for cluster-compatible graphs
    cluster_nodes <- mapply(function(g, o) .clusterNodes(g, o),
                            netgraphs[cluster_ids, drop = FALSE],
                            grouped_originals[cluster_ids, drop = FALSE],
                            SIMPLIFY = FALSE)
    
    ## Return nodes and represented original terms
    all_nodes <- as.list(rep(NA, length(netgraphs)))
    all_nodes[-cluster_ids] <- lca_nodes
    all_nodes[cluster_ids] <- cluster_nodes
    names(all_nodes) <- names(netgraphs)
    
    descs <- mapply(function(g, n, o)
        sapply(n, function(x)
            getDescs(g, x, o),
            simplify = FALSE,
            USE.NAMES = TRUE),
        netgraphs,
        all_nodes,
        grouped_originals,
        SIMPLIFY = FALSE)
    
    nodemap <- unlist(descs, recursive = FALSE)
    names(nodemap) <- unlist(all_nodes, use.names = FALSE)
    nodemap <- c(nodemap, fail_list)
    
    ## Get information on picked nodes and save as dataframe
    node_dbs <- unlist(lapply(names(nodemap), get_ontologies))
    nmat <- .displayNodes(node_dbs, names(nodemap))
    nmat$original_covered <- nodemap
    nmat$num_original_covered <- lengths(nodemap)
    nmat$num_original <- length(ids)
    
    return(nmat)
}
