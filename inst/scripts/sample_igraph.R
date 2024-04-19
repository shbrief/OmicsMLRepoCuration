## Sample list of ids for vignette
sample_ids <- c("CHEBI:166822", "NCIT:C47639", "FOODON:03600010", "NCIT:C29249", 
                "NCIT:C983", "NCIT:C247", "NCIT:C47384", "NCIT:C62002", "NCIT:C250", 
                "NCIT:C270", "NCIT:C94631", "NCIT:C281", "NCIT:C29711", "NCIT:C270", 
                "NCIT:C270", "NCIT:C29703", "NCIT:C274", "NCIT:C29750", "NCIT:C281", 
                "NCIT:C287", "NCIT:C287", "NCIT:C66930", "NCIT:C290", "NCIT:C29576", 
                "NCIT:C270", "NCIT:C333", "NCIT:C61686", "NCIT:C211", "NCIT:C128036", 
                "NCIT:C397", "NCIT:C29711", "NCIT:C65385", "NCIT:C448", "NCIT:C66883", 
                "NCIT:C98086", "NCIT:C93322", "NCIT:C93322", "NCIT:C47529", "NCIT:C98150", 
                "SNOMED:438451000124100", "NCIT:C1505", "NCIT:C47564", "NCIT:C98241", 
                "NCIT:C98085", "NCIT:C539", "NCIT:C581", "NCIT:C2654", "NCIT:C598", 
                "NCIT:C29124", "NCIT:C49186", "NCIT:C29148", "NCIT:C47564", "NCIT:C47564", 
                "NCIT:C29697", "NCIT:C61612", "NCIT:C29251", "NCIT:C642", "NCIT:C74453", 
                "NCIT:C80487", "NCIT:C68814", "NCIT:C41132", "NCIT:C47563", "NCIT:C257", 
                "NCIT:C1505", "NCIT:C1506", "NCIT:C47793", "NCIT:C128037", "NCIT:C106432", 
                "NCIT:C29723", "NCIT:C29723", "NCIT:C93144", "NCIT:C1589", "NCIT:C98083", 
                "NCIT:C73838", "NCIT:C47564", "NCIT:C1655", "NCIT:C1655", "NCIT:C843", 
                "NCIT:C97936", "NCIT:C49185", "NCIT:C29369", "NCIT:C1637", "SNOMED:372740001", 
                "SNOMED:48070003")

dir <- system.file("extdata", package = "OmicsMLRepoCuration")
readr::write_lines(sample_ids, file.path(dir, "sample_ids.csv"))

## Sample ontology term network for test
fromids <- c("NCIT:C1908", "NCIT:C1909", "NCIT:C78272", "NCIT:C29710", "NCIT:C1908",
             "NCIT:C1909", "NCIT:C78272", "NCIT:C241", "NCIT:C2198", "NCIT:C2356", 
             "NCIT:C257", "NCIT:C1908", "NCIT:C1909", "NCIT:C78276", "NCIT:C29711", 
             "NCIT:C1909", "NCIT:C471", "NCIT:C2846", "NCIT:C1908", "NCIT:C1909", 
             "NCIT:C78274", "NCIT:C270", "NCIT:C1909", "NCIT:C471", "NCIT:C783", 
             "NCIT:C1908", "NCIT:C1909", "NCIT:C254", "NCIT:C276", "NCIT:C250", 
             "NCIT:C1908", "NCIT:C1909", "NCIT:C93038", "NCIT:C1909", "NCIT:C78274", 
             "NCIT:C47793", "NCIT:C1908", "NCIT:C1909", "NCIT:C254", "NCIT:C276", 
             "NCIT:C1908", "NCIT:C1909", "NCIT:C78274", "NCIT:C1908", "NCIT:C1909", 
             "NCIT:C254", "NCIT:C1908", "NCIT:C1909", "NCIT:C78276")

toids <- c("NCIT:C1909", "NCIT:C78272", "NCIT:C29710", "NCIT:C47639",
           "NCIT:C1909", "NCIT:C78272", "NCIT:C241", "NCIT:C2198", "NCIT:C2356", 
           "NCIT:C257", "NCIT:C29249", "NCIT:C1909", "NCIT:C78276", "NCIT:C29711", 
           "NCIT:C983", "NCIT:C471", "NCIT:C2846", "NCIT:C983", "NCIT:C1909", 
           "NCIT:C78274", "NCIT:C270", "NCIT:C247", "NCIT:C471", "NCIT:C783", 
           "NCIT:C247", "NCIT:C1909", "NCIT:C254", "NCIT:C276", "NCIT:C250", 
           "NCIT:C47384", "NCIT:C1909", "NCIT:C93038", "NCIT:C62002", "NCIT:C78274", 
           "NCIT:C47793", "NCIT:C62002", "NCIT:C1909", "NCIT:C254", "NCIT:C276", 
           "NCIT:C250", "NCIT:C1909", "NCIT:C78274", "NCIT:C270", "NCIT:C1909", 
           "NCIT:C254", "NCIT:C281", "NCIT:C1909", "NCIT:C78276", "NCIT:C29711")

net <- data.frame(from = fromids,
                  to = toids)

dir <- system.file("extdata", package = "OmicsMLRepoCuration")
readr::write_csv(net, file.path(dir, "sample_net.csv"))

## Sample rols JSON tree representation for test
onto <- rols::Ontology("NCIT")
trm <- Term(onto, "NCIT:C274")
treeframe <- jsonlite::fromJSON(trm@links$jstree$href)[, 1:4]

dir <- system.file("extdata", package = "OmicsMLRepoCuration")
readr::write_csv(treeframe, file.path(dir, "sample_treeframe.csv"))
