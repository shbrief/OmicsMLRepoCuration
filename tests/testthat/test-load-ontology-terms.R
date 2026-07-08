# Tests for loadOntologyTerms() and its integration with
# validateDataAgainstSchema(), plus the anchored regex-pattern validation.

test_that("loadOntologyTerms parses labels and synonym_lookup", {
    tmp <- tempfile(fileext = ".json")
    writeLines(paste0('{"disease":{"labels":["asthma","Healthy"],',
                      '"synonym_lookup":{"bronchial asthma":"asthma",',
                      '"Well":"Healthy"}}}'), tmp)
    ot <- loadOntologyTerms(tmp)
    expect_named(ot, "disease")
    expect_equal(ot$disease$labels, c("asthma", "Healthy"))
    expect_equal(unname(ot$disease$synonym_lookup[["Well"]]), "Healthy")
    expect_equal(unname(ot$disease$synonym_lookup[["bronchial asthma"]]), "asthma")
})

test_that("loadOntologyTerms handles an empty synonym_lookup", {
    tmp <- tempfile(fileext = ".json")
    writeLines('{"country":{"labels":["China"],"synonym_lookup":{}}}', tmp)
    ot <- loadOntologyTerms(tmp)
    expect_equal(ot$country$labels, "China")
    expect_length(ot$country$synonym_lookup, 0)
})

test_that("loadOntologyTerms errors on a missing file", {
    expect_error(loadOntologyTerms(tempfile()), "not found")
})

test_that("loaded ontology_terms drive dynamic_enum validation", {
    tmp <- tempfile(fileext = ".json")
    writeLines(paste0('{"disease":{"labels":["adenoma","Healthy"],',
                      '"synonym_lookup":{"Well":"Healthy"}}}'), tmp)
    ot <- loadOntologyTerms(tmp)
    schema <- list(disease = list(
        col_class = "character",
        ontology = list(roots = "NCIT:C7057", property = "descendant")))
    # "Well" is a synonym of the static term "Healthy" -> flagged as synonym.
    data <- data.frame(disease = "Well", stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema, ontology_terms = ot)
    expect_true(any(grepl("recognized ontology synonym",
                          res$warnings, fixed = TRUE)))
    # "adenoma" (a label) passes silently.
    data2 <- data.frame(disease = "adenoma", stringsAsFactors = FALSE)
    res2 <- validateDataAgainstSchema(data2, schema, ontology_terms = ot)
    expect_false(any(grepl("'adenoma'", res2$warnings, fixed = TRUE)))
})

test_that("regex pattern is anchored to the whole value", {
    schema <- list(age = list(col_class = "character",
                              validation = list(pattern = "[0-9]+")))
    # "12abc" contains digits but is not all-digits: must now be flagged
    # (previously grepl() matched the substring and let it pass).
    data <- data.frame(age = c("12", "12abc"), stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema)
    expect_true(any(grepl("not matching pattern", res$warnings)))
})

test_that("fully-valid values pass the anchored pattern", {
    schema <- list(age = list(col_class = "character",
                              validation = list(pattern = "[0-9]+")))
    data <- data.frame(age = c("12", "007"), stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema)
    expect_false(any(grepl("not matching pattern", res$warnings)))
})

test_that("an already-anchored pattern still validates correctly", {
    schema <- list(v = list(col_class = "character",
                            validation = list(pattern = "^\\d+(\\.\\d+)?$")))
    data <- data.frame(v = c("3.14", "bad"), stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema)
    # "bad" flagged, "3.14" not.
    warns <- grep("not matching pattern", res$warnings, value = TRUE)
    expect_length(warns, 1L)
})
