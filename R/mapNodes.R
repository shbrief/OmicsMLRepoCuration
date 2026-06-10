#' Retrieves ideal representative nodes for a vector of ontology term ids
#' 
#' @importFrom dplyr distinct
#' @importFrom plyr compact
#' @importFrom purrr map
#' @importFrom stats setNames
#' @importFrom utils stack unstack
#' @importFrom igraph V
#' @importFrom jsonlite fromJSON
#' 
#' @param ids Character vector of term ids.
#' @param cutoff A numeric between 0 and 1. The maximum proportion of terms
#' covered by the chosen nodes. The 'universe' is all the input terms, the
#' shared root of them, and the terms between them. The smaller cutoff, the
#' more nodes will be returned. Defaults to 0.25.
#' 
#' @return A dataframe of chosen nodes including information on number of
#' original terms covered.
#' 
#' @export
#' 
#' @examples
#' ids <- c("CHEBI:166822", "NCIT:C47639", "FOODON:03600010", "NCIT:C29249",
#' "NCIT:C983", "NCIT:C247", "NCIT:C47384", "NCIT:C62002", "NCIT:C250",
#' "NCIT:C270", "NCIT:C94631", "NCIT:C281", "NCIT:C29711", "NCIT:C270")
#' 
#' # mapNodes(ids = ids, cutoff = 0.25)
#' 
mapNodes <- function(ids, cutoff = 0.25) {
    
    ## Get ontology information from ids
    dbs <- unlist(lapply(ids, getOntologies))
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
        fail_list <- stats::setNames(as.list(fail_names), fail_names)
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
    comp_nets <- purrr::map(split(big_nets, names(big_nets)), bind_rows)
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
        gnums <- lapply(utils::unstack(utils::stack(nums, drop = FALSE)), sum)
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
    node_dbs <- unlist(lapply(names(nodemap), getOntologies))
    nmat <- .displayNodes(node_dbs, names(nodemap))
    nmat$original_covered <- nodemap
    nmat$num_original_covered <- lengths(nodemap)
    nmat$num_original <- length(unique(ids))
    nmat <- nmat %>%
        rowwise() %>%
        mutate(original_covered = paste(original_covered, collapse = ";"))
    
    return(nmat)
}
