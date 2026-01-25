# Launch Shiny app for metadata curation

#' Launch the Metadata Curation Shiny App
#'
#' Opens an interactive Shiny application for curating and validating metadata
#' against the OmicsMLRepoCuration schema. The app provides features for data
#' upload, editing, validation, and schema browsing.
#'
#' @param launch.browser Logical. If TRUE (default), opens the app in the
#'   system's default web browser. If FALSE, the app opens in the RStudio
#'   viewer pane (if available).
#' @param port Integer. The TCP port that the application should listen on.
#'   If NULL (default), a random port is chosen.
#' @param host Character string. The IPv4 address that the application should
#'   listen on. Defaults to "127.0.0.1" (localhost).
#'
#' @return No return value. The function runs the Shiny app until it is stopped.
#'
#' @details
#' The Metadata Curation App provides an interactive interface for:
#' \itemize{
#'   \item Uploading CSV/TSV metadata files or creating new templates
#'   \item Editing data in an interactive table (add/delete rows and columns)
#'   \item Validating data against the schema with real-time feedback
#'   \item Browsing schema field definitions and requirements
#'   \item Checking dynamic enum configurations (ontology-based)
#'   \item Downloading curated and validated data
#' }
#'
#' The app validates against the current schema and highlights:
#' \itemize{
#'   \item Required fields (yellow background)
#'   \item Validation errors (missing required fields, type mismatches)
#'   \item Warnings (pattern violations, potential issues)
#'   \item Dynamic enum fields with ontology roots
#' }
#'
#' @examples
#' \dontrun{
#' # Launch app in browser
#' launch_curation_app()
#'
#' # Launch app in RStudio viewer
#' launch_curation_app(launch.browser = FALSE)
#'
#' # Launch on specific port
#' launch_curation_app(port = 3838)
#' }
#'
#' @section Required Packages:
#' The app requires the following packages to be installed:
#' \itemize{
#'   \item shiny
#'   \item shinydashboard
#'   \item DT
#'   \item yaml
#'   \item dplyr
#'   \item readr
#'   \item jsonlite
#' }
#'
#' Install missing packages with:
#' \code{install.packages(c("shiny", "shinydashboard", "DT", "yaml", "dplyr", "readr", "jsonlite"))}
#'
#' @section Workflow:
#' A typical curation workflow:
#' \enumerate{
#'   \item Upload existing metadata file or create a new template
#'   \item Edit data in the interactive table
#'   \item Run validation to check for errors
#'   \item Review validation results and fix issues
#'   \item Browse schema for field definitions as needed
#'   \item Download validated data
#' }
#'
#' @section Dynamic Enums:
#' The app supports dynamic enums that use ontology hierarchies:
#' \itemize{
#'   \item \strong{ancestry}: Uses HANCESTRO ontology children
#'   \item \strong{ancestry_details}: Uses HANCESTRO ontology descendants
#'   \item Check Schema Browser tab for specific ontology roots
#' }
#'
#' @importFrom shiny runApp
#' @export
launch_curation_app <- function(launch.browser = TRUE, port = NULL, host = "127.0.0.1") {
  
  # Check if required packages are installed
  required_pkgs <- c("shiny", "shinydashboard", "DT", "yaml", 
                     "dplyr", "readr", "jsonlite")
  
  missing_pkgs <- required_pkgs[!sapply(required_pkgs, requireNamespace, quietly = TRUE)]
  
  if (length(missing_pkgs) > 0) {
    stop(
      "The following packages are required but not installed:\n  ",
      paste(missing_pkgs, collapse = ", "),
      "\n\nInstall them with:\n  ",
      sprintf("install.packages(c('%s'))", paste(missing_pkgs, collapse = "', '")),
      call. = FALSE
    )
  }
  
  # Get app directory
  app_dir <- system.file("shiny", "metadata_curation_app", 
                         package = "OmicsMLRepoCuration")
  
  if (app_dir == "") {
    stop(
      "Could not find Shiny app directory.\n",
      "Make sure the package is properly installed.",
      call. = FALSE
    )
  }
  
  # Check if app.R exists
  if (!file.exists(file.path(app_dir, "app.R"))) {
    stop(
      "App file not found at: ", file.path(app_dir, "app.R"),
      call. = FALSE
    )
  }
  
  # Launch the app
  message("Launching Metadata Curation App...")
  message("App directory: ", app_dir)
  
  shiny::runApp(
    appDir = app_dir,
    launch.browser = launch.browser,
    port = port,
    host = host
  )
}
