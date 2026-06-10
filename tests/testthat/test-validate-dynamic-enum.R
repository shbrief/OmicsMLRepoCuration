# Tests for ontology-backed (dynamic_enum) field validation in
# validateDataAgainstSchema(). Ontology terms are injected explicitly via the
# `ontology_terms` argument so these tests need neither the bundled resource nor
# network/ontology access.

# Minimal field definition for an ontology-backed field. Pass a delimiter to
# make it multi-valued.
.onto_field <- function(roots = "NCIT:C25464", delimiter = NULL) {
    fd <- list(
        col_class = "character",
        ontology = list(roots = roots, property = "descendant")
    )
    if (!is.null(delimiter)) {
        fd$multiple_values <- TRUE
        fd$validation <- list(delimiter = delimiter)
    }
    fd
}

# Shared ontology-term fixture.
.onto_terms <- list(
    country = list(
        labels = c("China", "Austria", "United States of America"),
        synonym_lookup = c("CHN" = "China", "CN" = "China", "AUT" = "Austria")
    ),
    disease = list(
        # "Healthy" stands in for a static.enum term merged into the dynamic set;
        # "Well" is its synonym.
        labels = c("adenoma", "asthma", "Healthy"),
        synonym_lookup = c("bronchial asthma" = "asthma", "Well" = "Healthy")
    )
)

test_that("preferred labels pass with no enum warnings", {
    schema <- list(country = .onto_field())
    data <- data.frame(country = c("China", "Austria"), stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema, ontology_terms = .onto_terms)
    expect_false(any(grepl("synonym|recognized term", res$warnings)))
})

test_that("a recognized ontology synonym is flagged without naming a label", {
    schema <- list(country = .onto_field())
    data <- data.frame(country = "CHN", stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema, ontology_terms = .onto_terms)
    expect_true(any(grepl(
        "'CHN' is a recognized ontology synonym, not the preferred label",
        res$warnings, fixed = TRUE)))
    # Must NOT assert a specific preferred label (ambiguity guard).
    expect_false(any(grepl("China", res$warnings, fixed = TRUE)))
})

test_that("an unrecognized value warns as not a recognized term", {
    schema <- list(country = .onto_field())
    data <- data.frame(country = "Atlantis", stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema, ontology_terms = .onto_terms)
    expect_true(any(grepl(
        "'Atlantis' is not a recognized term", res$warnings, fixed = TRUE)))
})

test_that("repeated bad values are reported once with an occurrence count", {
    schema <- list(country = .onto_field())
    data <- data.frame(country = rep("CHN", 5), stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema, ontology_terms = .onto_terms)
    chn <- grep("'CHN'", res$warnings, value = TRUE, fixed = TRUE)
    expect_length(chn, 1L)             # de-duplicated, not 5 messages
    expect_match(chn, "(5 rows)", fixed = TRUE)
})

test_that("multi-valued cells split on the delimiter and flag only bad tokens", {
    schema <- list(disease = .onto_field(delimiter = ";"))
    data <- data.frame(disease = "adenoma;Bogusoma", stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema, ontology_terms = .onto_terms)
    expect_true(any(grepl("'Bogusoma' is not a recognized term",
                          res$warnings, fixed = TRUE)))
    expect_false(any(grepl("'adenoma'", res$warnings, fixed = TRUE)))
})

test_that("wildcard values are skipped", {
    schema <- list(country = .onto_field())
    data <- data.frame(country = c("Not reported", "Not applicable"),
                       stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema, ontology_terms = .onto_terms)
    expect_false(any(grepl("synonym|recognized term", res$warnings)))
})

test_that("fields absent from ontology_terms are not enum-validated", {
    schema <- list(country = .onto_field())
    data <- data.frame(country = "CHN", stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema, ontology_terms = list())
    expect_false(any(grepl("synonym|recognized term", res$warnings)))
})

test_that("a static.enum term merged into the set passes; its synonym is flagged", {
    schema <- list(disease = .onto_field(delimiter = ";"))
    # "Healthy" is a static term (not an NCIT:C7057 descendant) merged into the
    # field's label set, so it must pass silently alongside a dynamic term.
    data <- data.frame(disease = "Healthy;adenoma", stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema, ontology_terms = .onto_terms)
    expect_false(any(grepl("'Healthy'", res$warnings, fixed = TRUE)))
    expect_false(any(grepl("'adenoma'", res$warnings, fixed = TRUE)))

    # A synonym of the static term is still flagged as a synonym.
    data2 <- data.frame(disease = "Well", stringsAsFactors = FALSE)
    res2 <- validateDataAgainstSchema(data2, schema, ontology_terms = .onto_terms)
    expect_true(any(grepl(
        "'Well' is a recognized ontology synonym, not the preferred label",
        res2$warnings, fixed = TRUE)))
})

test_that("dynamic_enum + static_enum fields get both checks (e.g. treatment)", {
    schema <- list(treatment = list(
        col_class = "character",
        multiple_values = TRUE,
        validation = list(delimiter = ";",
                          allowed_values = c("aspirin", "ibuprofen")),
        ontology = list(roots = "NCIT:C1908", property = "descendant")
    ))
    onto <- list(treatment = list(
        labels = c("aspirin", "ibuprofen"),
        synonym_lookup = c("ASA" = "aspirin")
    ))
    data <- data.frame(treatment = "ASA", stringsAsFactors = FALSE)
    res <- validateDataAgainstSchema(data, schema, ontology_terms = onto)
    # Static-enum branch: "ASA" is not in allowed_values.
    expect_true(any(grepl("Allowed values", res$warnings, fixed = TRUE)))
    # Dynamic-enum branch: "ASA" is flagged as a recognized synonym.
    expect_true(any(grepl(
        "'ASA' is a recognized ontology synonym, not the preferred label",
        res$warnings, fixed = TRUE)))
})
