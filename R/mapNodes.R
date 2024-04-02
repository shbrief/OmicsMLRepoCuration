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
        
        if (!is.character(jstree)) {
            print("Unable to access tree, proceeding to next term")
            jstree <- "no tree"
        }
        
        ## Add link to list, named by term id
        all_trees <- c(all_trees, jstree)
        names(all_trees)[i] <- terms[i]
    }
    return(all_trees)
}

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
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' tree_frame <- read.csv(file.path(dir, "sample_treeframe.csv"))  
#'
#' .createNetwork(tree_frame = tree_frame)
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
#' .groupRoots(nets) 
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
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#'
#' graph <- igraph::graph_from_data_frame(d = net,
#' vertices = unique(unlist(net)))
#' 
#' vex <- c("NCIT:C270", "NCIT:C93038")
#'
#' .LCA(graph = graph, vex = vex)
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
    lcas <- rownames(dists)[which(dists == max(dists))]
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
#' .bestRoots(graph = graph, vex = vex, ovex = ovex)
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
#' .consolidateNodes(graph = graph, nodes = nodes)
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
#' .getDescs(graph = graph, node = "NCIT:C78274",
#' original_terms = original_terms)
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
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#' 
#' original_terms <- c("NCIT:C29711", "NCIT:C270", "NCIT:C250", "NCIT:C47639",
#' "NCIT:C29249", "NCIT:C983", "NCIT:C247", "NCIT:C47384", "NCIT:C62002",
#' "NCIT:C281")
#' 
#' .createGraph(net = net, original_terms = original_terms)
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
        mutate(type = case_when(vex == root ~ "root",
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
#' @examples
#' dir <- system.file("extdata", package = "OmicsMLRepoCuration")
#' net <- read.csv(file.path(dir, "sample_net.csv"))
#' 
#' netgraph <- igraph::graph_from_data_frame(d = net,
#' vertices = unique(unlist(net)))
#' 
#' .busyNodes(netgraph = netgraph, max_nodes = 20)
#'
.busyNodes <- function(netgraph, max_nodes) {
    
    ## Use descendant number cutoff to identify high-traffic nodes
    dnums <- unlist(lapply(V(netgraph), function(x)
        length(dfs(netgraph, x, mode = "out", unreachable = FALSE)$order)))
    remnodes <- names(which(dnums > max_nodes))
    return(remnodes)
}

#' Retrieves ontology terms and database information for given term ids
#'
#' @import rols
#' 
#' @param onto A character vector. Name(s) of ontologies that terms are from.
#' @param node A character vector of ontology term IDs.
#' 
#' @return Dataframe of submitted term IDs, term names, and term ontologies
#' 
#' @examples
#' onto <- c("FOODON", "CHEBI", "NCIT", "NCIT", "NCIT", "SNOMED", "SNOMED",
#' "SNOMED")
#' node <- c("FOODON:03600010", "CHEBI:166822", "NCIT:C1908", "NCIT:C41132",
#' "NCIT:C25218", "SNOMED:438451000124100", "SNOMED:372740001",
#' "SNOMED:48070003")
#' 
#' .displayNodes(onto = onto, node = node)
#' 
.displayNodes <- function(onto, node) {
    
    ## Initialize dataframe to store term information
    dmat <- as.data.frame(matrix(nrow = sum(lengths(node)),
                                 ncol = 3,
                                 dimnames = list(c(), c("ontology_term",
                                                        "ontology_term_id",
                                                        "original_term_ontology"))))
    
    ## Save individual picked nodes with their respective ontologies
    dmat$ontology_term_id <- unname(unlist(node))
    dmat$original_term_ontology <- onto
    
    ## Loop through picked nodes and get additional information
    for (i in 1:nrow(dmat)) {
        curont <- dmat$original_term_ontology[i]
        curid <- dmat$ontology_term_id[i]
        print(paste0("Retrieving info for picked node ", curid))
        
        qry <- OlsSearch(q = curid, exact = TRUE)
        qry <- olsSearch(qry)
        qdrf <- as(qry, "data.frame")
        
        if (curont %in% qdrf$ontology_prefix) {
            record <- qdrf[qdrf$ontology_prefix == curont, ][1,]
        } else if (TRUE %in% qdrf$is_defining_ontology) {
            record <- qdrf[qdrf$is_defining_ontology == TRUE, ]
        } else {
            record <- qdrf[1, ]
        }
        dmat$ontology_term[i] <- record$label
    }
    return(dmat)
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
#' .clusterNodes(netgraph = netgraph, original_terms = original_terms,
#' max_nodes = 20)
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

#' Retrieves ideal representative nodes for a vector of ontology term ids
#' 
#' @importFrom dplyr distinct
#' @importFrom plyr compact
#' @importFrom igraph V
#' 
#' @param ids Character vector of term ids.
#' 
#' @return A dataframe of chosen nodes including information on number of 
#' original terms covered.
#' 
#' @examples
#' ids <- c("CHEBI:166822", "NCIT:C47639", "FOODON:03600010", "NCIT:C29249",
#' "NCIT:C983", "NCIT:C247", "NCIT:C47384", "NCIT:C62002", "NCIT:C250",
#' "NCIT:C270", "NCIT:C94631", "NCIT:C281", "NCIT:C29711", "NCIT:C270")
#' 
#' mapNodes(ids = ids, cutoff = 0.25)
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
    tree_nets <- lapply(tree_frames, function(x) lapply(x, .createNetwork))
    tree_groups <- lapply(tree_nets, .groupRoots)
    big_nets <- unlist(lapply(tree_groups, function(x) lapply(x, bind_rows)),
                       recursive = FALSE)
    names(big_nets) <- lapply(names(big_nets), function(x)
        unlist(strsplit(x, split  = "\\."))[2])
    comp_nets <- map(split(big_nets, names(big_nets)), bind_rows)
    grouped_terms <- lapply(comp_nets, function(x) unique(unlist(x)))
    grouped_originals <- lapply(grouped_terms, function(x) x[x %in% ids])
    netgraphs <- mapply(function(n, o) .createGraph(n, o),
                        comp_nets, grouped_originals, SIMPLIFY = FALSE)
    
    ## Separate different-sized graphs
    ## for either LCA or cluster-based node selection
    ontos <- unlist(lapply(names(netgraphs), function(x) unlist(strsplit(x, split = ":"))[1]))
    nums <- lapply(netgraphs, function(x) length(V(x)))
    names(nums) <- ontos
    if (any(duplicated(ontos))) {
        gnums <- lapply(unstack(stack(nums, drop = FALSE)), sum)
        numall <- gnums[ontos]
    } else {
        numall <- nums
    }

    single <- lengths(grouped_originals) == 1

    test_cuts <- mapply(function(n, m) length(.busyNodes(n, m * cutoff)),
                        netgraphs,
                        numall,
                        SIMPLIFY = FALSE)
    clust <- test_cuts != 0
    
    cluster_ids <- which(!single & clust)
    lca_ids <- seq_along(netgraphs)[-cluster_ids]
    if (length(cluster_ids) == 0) {
        cluster_ids <- c(0)
        lca_ids <- seq_along(netgraphs)
    }
    
    ## Select nodes for LCA-compatible graphs
    lca_nodes <- mapply(function(g, o) .LCA(g, o),
                        netgraphs[lca_ids, drop = FALSE],
                        grouped_originals[lca_ids, drop = FALSE],
                        SIMPLIFY = FALSE)
    
    ## Select nodes for cluster-compatible graphs
    cluster_nodes <- mapply(function(g, o, m) .clusterNodes(g, o, m * cutoff),
                            netgraphs[cluster_ids, drop = FALSE],
                            grouped_originals[cluster_ids, drop = FALSE],
                            numall[cluster_ids, drop = FALSE],
                            SIMPLIFY = FALSE)
    
    ## Return nodes and represented original terms
    all_nodes <- as.list(rep(NA, length(netgraphs)))
    all_nodes[lca_ids] <- lca_nodes
    all_nodes[cluster_ids] <- cluster_nodes
    names(all_nodes) <- names(netgraphs)
    
    descs <- mapply(function(g, n, o)
        sapply(n, function(x)
            .getDescs(g, x, o),
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
    nmat$num_original <- length(unique(ids))
    nmat <- nmat %>%
        rowwise() %>%
        mutate(original_covered = paste(original_covered, collapse = ";"))
    
    return(nmat)
}
