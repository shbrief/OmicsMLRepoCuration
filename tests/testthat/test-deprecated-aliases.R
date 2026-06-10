test_that("deprecated snake_case aliases warn and forward to camelCase", {
    terms <- c("HP:0001824", "MONDO:0010200", "NCIT:C122328")

    # Alias warns via .Deprecated()
    expect_warning(get_ontologies(terms), "deprecated")

    # Alias returns the same result as the new function
    expect_identical(
        suppressWarnings(get_ontologies(terms)),
        getOntologies(terms)
    )
})

test_that("formatList alias forwards correctly", {
    expect_warning(format_list(list("a", "b", "a"), ";"), "deprecated")
    expect_identical(
        suppressWarnings(format_list(list("a", "b", "a"), ";")),
        formatList(list("a", "b", "a"), ";")
    )
})
