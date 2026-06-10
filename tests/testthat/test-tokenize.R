test_that(".tokenizeCells splits, trims, drops empties and wildcards", {
    tok <- OmicsMLRepoCuration:::.tokenizeCells

    # Splits on the delimiter, trims whitespace, drops empty tokens
    expect_identical(tok("a; b ; ;c", ";", NULL), c("a", "b", "c"))

    # Removes wildcard values
    expect_identical(tok("a;b;c", ";", "b"), c("a", "c"))

    # NULL delimiter treats each value as a single token
    expect_identical(tok(c("a", "b"), NULL, NULL), c("a", "b"))

    # Handles a vector of multi-valued cells
    expect_identical(tok(c("a;b", "c;d"), ";", NULL), c("a", "b", "c", "d"))
})
