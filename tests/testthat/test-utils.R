test_that("getOntologies extracts ontology prefixes correctly", {
    terms <- c("HP:0001824", "MONDO:0010200", "NCIT:C122328")
    result <- getOntologies(terms)
    expect_equal(result, c("HP", "MONDO", "NCIT"))
})

test_that("getOntologies identifies SNOMED terms", {
    terms <- c("4471000175100")
    result <- getOntologies(terms)
    expect_equal(result, "SNOMED")
})

test_that("strVsplit splits and returns unique values", {
    terms <- c("a;b;c", "b;c;d")
    result <- strVsplit(terms, ";")
    expect_true(all(c("a", "b", "c", "d") %in% result))
    expect_equal(length(result), 4)
})
