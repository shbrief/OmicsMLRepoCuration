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
