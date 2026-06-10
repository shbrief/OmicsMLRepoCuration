## A small in-memory schema used across the accessor tests so they do not
## depend on the bundled data dictionary's exact structure.
.test_schema <- function() {
    list(
        schema_info = list(version = "test"),
        validation_rules = list(),
        field_a = list(required = TRUE, category = "demographic",
                       col_class = "character"),
        field_b = list(required = FALSE, category = "clinical"),
        field_c = list(required = TRUE, category = "demographic")
    )
}

test_that("getRequiredFields returns only required fields", {
    expect_identical(getRequiredFields(.test_schema()), c("field_a", "field_c"))
})

test_that("getFieldsByCategory filters by category and skips metadata", {
    expect_identical(getFieldsByCategory(.test_schema(), "demographic"),
                     c("field_a", "field_c"))
    expect_identical(getFieldsByCategory(.test_schema(), "clinical"), "field_b")
})

test_that("getAllCategories returns unique categories excluding metadata", {
    expect_setequal(getAllCategories(.test_schema()),
                    c("demographic", "clinical"))
})

test_that("getFieldDefinition returns a field or errors when absent", {
    fd <- getFieldDefinition(.test_schema(), "field_a")
    expect_true(fd$required)
    expect_identical(fd$category, "demographic")
    expect_error(getFieldDefinition(.test_schema(), "missing_field"),
                 "not found")
})

test_that("loadMetadataSchema round-trips a YAML file", {
    tmp <- tempfile(fileext = ".yaml")
    on.exit(unlink(tmp), add = TRUE)
    yaml::write_yaml(.test_schema(), tmp)
    loaded <- loadMetadataSchema(tmp)
    expect_type(loaded, "list")
    expect_identical(getRequiredFields(loaded), c("field_a", "field_c"))
})
