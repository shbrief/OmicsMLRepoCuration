test_that("checkCurationStats returns available fields", {
    df <- data.frame(col1 = c(1, 2, NA), col2 = c("a", NA, "c"))
    result <- checkCurationStats("col1", DB = df, show_available_fields = TRUE)
    expect_equal(result, c("col1", "col2"))
})

test_that("checkCurationStats calculates completeness", {
    df <- data.frame(col1 = c(1, 2, NA), col2 = c("a", NA, "c"))
    result <- checkCurationStats("col1", check = "completeness", DB = df)
    expect_equal(result, "67")
})

test_that("checkCurationStats errors without DB", {
    expect_error(checkCurationStats("col1"),
                 "Provide the database")
})
