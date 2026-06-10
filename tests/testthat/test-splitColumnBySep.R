test_that("splitColumnBySep splits by separator into two columns with content", {
    df <- data.frame(x = c("name:value1", "name:value2"), stringsAsFactors = FALSE)
    result <- splitColumnBySep(df, "x", sep = ":")
    expect_true(ncol(result) >= 2)
    expect_identical(result$x, c("name", "name"))
    expect_identical(result$x_value, c("value1", "value2"))
})

test_that("splitColumnBySep with delim + sep produces aligned wide columns", {
    df <- data.frame(id = 1, feat = "a:1<;>b:2", stringsAsFactors = FALSE)
    result <- splitColumnBySep(df, "feat", delim = "<;>", sep = ":",
                               keep_delim = TRUE)
    expect_identical(result$feat, "a<;>b")
    expect_identical(result$feat_value, "1<;>2")
})

test_that("splitColumnBySep sep-only honors position first vs last", {
    df <- data.frame(x = c("a:b:c", "p:q"), stringsAsFactors = FALSE)

    first <- splitColumnBySep(df, "x", sep = ":", position = "first")
    expect_identical(first$x, c("a", "p"))
    expect_identical(first$x_value, c("b:c", "q"))

    last <- splitColumnBySep(df, "x", sep = ":", position = "last")
    expect_identical(last$x, c("a:b", "p"))
    expect_identical(last$x_value, c("c", "q"))
})

test_that("splitColumnBySep keep_delim honors position first vs last", {
    df <- data.frame(id = 1, f = "a:1:x<;>b:2", stringsAsFactors = FALSE)

    first <- splitColumnBySep(df, "f", delim = "<;>", sep = ":",
                              keep_delim = TRUE, position = "first")
    expect_identical(first$f, "a<;>b")
    expect_identical(first$f_value, "1:x<;>2")

    last <- splitColumnBySep(df, "f", delim = "<;>", sep = ":",
                             keep_delim = TRUE, position = "last")
    expect_identical(last$f, "a:1<;>b")
    expect_identical(last$f_value, "x<;>2")
})

test_that("splitColumnBySep converts the string 'NA' to a real NA", {
    df <- data.frame(x = c("name:NA", "name:5"), stringsAsFactors = FALSE)
    result <- splitColumnBySep(df, "x", sep = ":")
    expect_true(is.na(result$x_value[1]))
    expect_identical(result$x_value[2], "5")
})

test_that("splitColumnBySep splits by delimiter into long format", {
    df <- data.frame(id = 1, x = "a;b;c", stringsAsFactors = FALSE)
    result <- splitColumnBySep(df, "x", delim = ";", expand_rows = TRUE)
    expect_true(nrow(result) > 1)
})
