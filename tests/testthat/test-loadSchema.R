test_that("loadMetadataSchema loads YAML schema", {
    schema_file <- system.file("schema", "cmd_data_dictionary.yaml",
                               package = "OmicsMLRepoCuration")
    skip_if(!file.exists(schema_file), "Schema file not found")
    schema <- loadMetadataSchema(schema_file)
    expect_type(schema, "list")
    expect_true(length(schema) > 0)
})

test_that("loadMetadataSchema errors on missing file", {
    expect_error(loadMetadataSchema("nonexistent_file.yaml"))
})
