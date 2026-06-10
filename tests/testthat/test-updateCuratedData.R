test_that("formatList removes duplicates and cleans delimiters", {
    result <- formatList(list("red", "yellow", "red", "blue", "", ""), ";")
    expect_true(!grepl("^;|;$", result))
    expect_true(grepl("red", result))
    expect_true(grepl("yellow", result))
    expect_true(grepl("blue", result))
})

test_that("mapValues maps original to curated values", {
    ex_df <- data.frame(
        original_value = c("gold", "gold"),
        curated_ontology = c("Yellow", "Gold"),
        curated_ontology_term_id = c("123", "456")
    )
    result <- mapValues(ex_df, "curated_ontology", "<;>", "gold")
    expect_true(grepl("Yellow", result))
    expect_true(grepl("Gold", result))
})

test_that("updateCuratedData remaps a column end-to-end", {
    ex_map <- data.frame(
        original_value = c("gold", "gold", "blue", "teal", "teal"),
        curated_ontology = c("Yellow", "Gold", "Blue", "Teal", "Blue"),
        curated_ontology_term_id = c("123", "456", "777", "333", "777")
    )
    ex_data <- data.frame(
        original_color = c("blue", "gold", "teal"),
        curated_color = c("Blue", "Gold", "Teal"),
        curated_color_ontology_term_id = c("777", "456", "333")
    )
    result <- updateCuratedData(ex_data, ex_map, "color", "<;>")

    # A one-to-one mapping stays a single value
    expect_identical(result$curated_color[1], "Blue")
    expect_identical(result$curated_color_ontology_term_id[1], "777")
    # A one-to-many mapping is collapsed on the delimiter
    expect_identical(result$curated_color[2], "Yellow<;>Gold")
    expect_identical(result$curated_color_ontology_term_id[2], "123<;>456")
    expect_identical(result$curated_color[3], "Teal<;>Blue")
})
