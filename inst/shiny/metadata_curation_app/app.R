#
# Metadata Curation and Validation Shiny App
# OmicsMLRepoCuration Package
# ODM-inspired interface
#

library(shiny)
library(shinydashboard)
library(DT)
library(OmicsMLRepoCuration)
library(yaml)
library(dplyr)
library(readr)
library(jsonlite)

# Load schema
schema_file <- system.file("schema", "cmd_schema.yaml", 
                          package = "OmicsMLRepoCuration")
schema <- load_metadata_schema(schema_file)

# Get required fields and all field names
required_fields <- get_required_fields(schema)
all_fields <- setdiff(names(schema), c("schema_info", "validation_rules", "metadata"))

# UI Definition
ui <- dashboardPage(
  skin = "purple",
  
  # Header
  dashboardHeader(
    title = "Omics Metadata Manager",
    titleWidth = 300
  ),
  
  # Sidebar
  dashboardSidebar(
    width = 280,
    sidebarMenu(
      id = "tabs",
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Import Data", tabName = "upload", icon = icon("file-import")),
      menuItem("Data Editor", tabName = "editor", icon = icon("table")),
      menuItem("Data Curation", tabName = "curation", icon = icon("magic")),
      menuItem("Quality Control", tabName = "validation", icon = icon("check-double")),
      menuItem("Ontology Browser", tabName = "ontology", icon = icon("sitemap")),
      menuItem("Export", tabName = "export", icon = icon("file-export")),
      menuItem("Help", tabName = "help", icon = icon("question-circle"))
    ),
    hr(),
    div(style = "padding: 15px;",
        h5("Project Stats", style = "color: white; font-weight: bold;"),
        uiOutput("sidebar_stats")
    )
  ),
  
  # Body
  dashboardBody(
    tags$head(
      tags$style(HTML("
        /* ODM-inspired styling */
        .main-header .logo { font-weight: bold; font-size: 18px; }
        .main-header .navbar { background-color: #6f42c1; }
        .content-wrapper { background-color: #f4f6f9; }
        .box { border-top: 3px solid #6f42c1; box-shadow: 0 1px 3px rgba(0,0,0,0.12); }
        .box-header { font-weight: bold; background-color: #fafafa; }
        .box-title { font-size: 16px; color: #333; }
        
        /* Field highlighting */
        .required-field { background-color: #fff3e0 !important; border-left: 3px solid #ff9800; }
        .error-field { background-color: #ffebee !important; border-left: 3px solid #f44336; }
        .warning-field { background-color: #fff9e6 !important; border-left: 3px solid #ffc107; }
        .valid-field { background-color: #e8f5e9 !important; border-left: 3px solid #4caf50; }
        
        /* Status indicators */
        .validation-error { color: #f44336; font-weight: bold; }
        .validation-warning { color: #ff9800; font-weight: bold; }
        .validation-success { color: #4caf50; font-weight: bold; }
        
        /* Badges */
        .dynamic-enum-badge { 
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: white; 
          padding: 3px 8px; 
          border-radius: 12px; 
          font-size: 11px;
          font-weight: bold;
          display: inline-block;
          margin: 2px;
        }
        .static-enum-badge { 
          background-color: #607d8b; 
          color: white; 
          padding: 3px 8px; 
          border-radius: 12px; 
          font-size: 11px;
          font-weight: bold;
          display: inline-block;
          margin: 2px;
        }
        .required-badge {
          background-color: #ff9800;
          color: white;
          padding: 2px 6px;
          border-radius: 3px;
          font-size: 10px;
          font-weight: bold;
          margin-left: 5px;
        }
        
        /* Cards */
        .field-card { 
          margin-bottom: 15px; 
          padding: 15px; 
          border: 1px solid #e0e0e0; 
          border-radius: 8px;
          background-color: white;
          box-shadow: 0 2px 4px rgba(0,0,0,0.08);
          transition: all 0.3s ease;
        }
        .field-card:hover {
          box-shadow: 0 4px 8px rgba(0,0,0,0.15);
          transform: translateY(-2px);
        }
        
        /* Info boxes */
        .info-box { 
          margin-bottom: 15px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          border-radius: 4px;
        }
        .info-box-icon { border-radius: 4px 0 0 4px; }
        
        /* Buttons */
        .btn-primary { 
          background-color: #6f42c1; 
          border-color: #6f42c1;
          font-weight: bold;
        }
        .btn-primary:hover { 
          background-color: #5a32a3; 
          border-color: #5a32a3;
        }
        
        /* Tables */
        .dataTables_wrapper { font-size: 13px; }
        table.dataTable thead th { 
          background-color: #f5f5f5; 
          font-weight: bold;
          border-bottom: 2px solid #6f42c1;
        }
        
        /* Progress bars */
        .progress { height: 25px; border-radius: 4px; }
        .progress-bar { font-weight: bold; }
        
        /* Quality metrics */
        .metric-card {
          background: white;
          padding: 20px;
          border-radius: 8px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          margin-bottom: 15px;
          text-align: center;
        }
        .metric-value {
          font-size: 36px;
          font-weight: bold;
          color: #6f42c1;
        }
        .metric-label {
          font-size: 14px;
          color: #666;
          margin-top: 5px;
        }
      "))
    ),
    
    tabItems(
      # Dashboard Tab
      tabItem(
        tabName = "dashboard",
        fluidRow(
          box(
            title = "Welcome to Omics Metadata Manager",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            h3("Quality Metrics Overview"),
            p("Monitor your metadata curation progress and quality metrics.")
          )
        ),
        fluidRow(
          valueBoxOutput("vbox_samples", width = 3),
          valueBoxOutput("vbox_fields", width = 3),
          valueBoxOutput("vbox_completeness", width = 3),
          valueBoxOutput("vbox_quality", width = 3)
        ),
        fluidRow(
          box(
            title = "Completeness by Field",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotOutput("completeness_plot", height = "300px")
          ),
          box(
            title = "Validation Status",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            plotOutput("validation_plot", height = "300px")
          )
        ),
        fluidRow(
          box(
            title = "Quick Actions",
            status = "success",
            solidHeader = TRUE,
            width = 12,
            actionButton("goto_import", "Import Data", class = "btn-primary btn-lg", icon = icon("upload")),
            actionButton("goto_editor", "Edit Data", class = "btn-info btn-lg", icon = icon("edit")),
            actionButton("goto_validate", "Validate", class = "btn-warning btn-lg", icon = icon("check")),
            actionButton("goto_export", "Export", class = "btn-success btn-lg", icon = icon("download"))
          )
        )
      ),
      
      # Upload Tab
      tabItem(
        tabName = "upload",
        fluidRow(
          box(
            title = "Import Metadata", 
            status = "primary", 
            solidHeader = TRUE,
            width = 8,
            icon = icon("file-import"),
            h4("Upload from File"),
            fileInput("file_upload", "Choose CSV, TSV, or Excel File",
                     accept = c("text/csv", "text/tab-separated-values",
                               ".csv", ".tsv", ".txt", ".xlsx", ".xls"),
                     width = "100%"),
            fluidRow(
              column(6,
                checkboxInput("header", "File has header row", TRUE)
              ),
              column(6,
                radioButtons("sep", "Separator:",
                           choices = c("Comma" = ",", "Tab" = "\t", "Semicolon" = ";"),
                           selected = ",", inline = TRUE)
              )
            ),
            actionButton("load_data", "Import Data", 
                        class = "btn-primary btn-lg btn-block", 
                        icon = icon("upload")),
            hr(),
            h4("Or Start from Template"),
            fluidRow(
              column(6,
                numericInput("n_rows", "Number of samples:", 
                           value = 10, min = 1, max = 1000, width = "100%")
              ),
              column(6,
                selectInput("template_type", "Template type:",
                          choices = c("Minimal (required fields only)" = "minimal",
                                    "Standard (common fields)" = "standard"),
                          width = "100%")
              )
            ),
            actionButton("create_template", "Create from Template", 
                        class = "btn-success btn-lg btn-block", icon = icon("plus-square"))
          ),
          box(
            title = "Import Options",
            status = "info",
            solidHeader = TRUE,
            width = 4,
            h5("Supported Formats:"),
            tags$ul(
              tags$li("CSV (Comma-separated)"),
              tags$li("TSV (Tab-separated)"),
              tags$li("Excel (.xlsx, .xls)"),
              tags$li("Custom delimiters")
            ),
            hr(),
            h5("Data Requirements:"),
            tags$ul(
              tags$li("Column names must match schema"),
              tags$li("Required fields must be present"),
              tags$li("Use standard ontology IDs"),
              tags$li("Check delimiter for multi-values")
            ),
            hr(),
            actionButton("load_demo", "Load Demo Data", 
                        class = "btn-info btn-block", icon = icon("flask"))
          )
        ),
        fluidRow(
          box(
            title = "Data Preview",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            icon = icon("eye"),
            uiOutput("upload_summary"),
            hr(),
            DTOutput("upload_preview")
          )
        )
      ),
      
      # Editor Tab
      tabItem(
        tabName = "editor",
        fluidRow(
          box(
            title = "Metadata Editor",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            icon = icon("table"),
            fluidRow(
              column(12,
                div(style = "margin-bottom: 15px;",
                  actionButton("add_row", "Add Sample", icon = icon("plus"), 
                              class = "btn-success"),
                  actionButton("delete_row", "Delete Selected", 
                              icon = icon("trash"), class = "btn-danger"),
                  actionButton("duplicate_row", "Duplicate Sample", 
                              icon = icon("copy"), class = "btn-info"),
                  actionButton("add_column", "Add Field", icon = icon("columns"),
                              class = "btn-info"),
                  actionButton("validate_inline", "Quick Validate", 
                              icon = icon("check"), class = "btn-warning"),
                  div(style = "float: right;",
                    downloadButton("download_data", "Download", class = "btn-primary")
                  )
                )
              )
            ),
            uiOutput("editor_info"),
            hr(),
            DTOutput("data_table")
          )
        ),
        fluidRow(
          box(
            title = "Add Field",
            status = "info",
            collapsible = TRUE,
            collapsed = TRUE,
            width = 12,
            fluidRow(
              column(6,
                selectInput("new_column_select", "Select from Schema:",
                           choices = NULL, width = "100%")
              ),
              column(6,
                textInput("new_column_name", "Or enter custom field name:",
                         width = "100%")
              )
            ),
            actionButton("confirm_add_column", "Add Field", 
                        class = "btn-primary", icon = icon("plus"))
          )
        )
      ),
      
      # Quality Control Tab
      tabItem(
        tabName = "validation",
        fluidRow(
          infoBoxOutput("valid_box", width = 3),
          infoBoxOutput("error_box", width = 3),
          infoBoxOutput("warning_box", width = 3),
          infoBoxOutput("completeness_box", width = 3)
        ),
        fluidRow(
          box(
            title = "Quality Control Actions",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            icon = icon("check-double"),
            actionButton("run_validation", "Run Full Validation", 
                        icon = icon("play"), class = "btn-primary btn-lg"),
            actionButton("validate_required", "Check Required Fields",
                        icon = icon("exclamation-triangle"), class = "btn-warning"),
            actionButton("validate_types", "Check Data Types",
                        icon = icon("database"), class = "btn-info"),
            actionButton("clear_validation", "Clear Results",
                        icon = icon("eraser"), class = "btn-secondary")
          )
        ),
        fluidRow(
          box(
            title = "Validation Results",
            status = "warning",
            solidHeader = TRUE,
            width = 6,
            icon = icon("list-alt"),
            verbatimTextOutput("validation_results")
          ),
          box(
            title = "Issues Summary",
            status = "danger",
            solidHeader = TRUE,
            width = 6,
            icon = icon("exclamation-circle"),
            uiOutput("issues_summary")
          )
        ),
        fluidRow(
          box(
            title = "Field Completeness Report",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            icon = icon("chart-bar"),
            DTOutput("field_validation_table")
          )
        )
      ),
      
      # Data Curation Tab
      tabItem(
        tabName = "curation",
        fluidRow(
          box(
            title = "Data Curation Tools",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            icon = icon("magic"),
            p("Use these tools to standardize, map, and clean your metadata values.")
          )
        ),
        
        # Ontology Term Mapping
        fluidRow(
          box(
            title = "Ontology Term Mapping",
            status = "info",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            icon = icon("project-diagram"),
            p("Map free-text values to standardized ontology terms using intelligent search."),
            fluidRow(
              column(4,
                selectInput("map_field", "Select field to map:",
                           choices = NULL, width = "100%")
              ),
              column(4,
                selectInput("map_ontology", "Target ontology:",
                           choices = c("HANCESTRO" = "hancestro",
                                     "NCIT" = "ncit",
                                     "EFO" = "efo",
                                     "HP" = "hp",
                                     "MONDO" = "mondo"),
                           width = "100%")
              ),
              column(4,
                numericInput("map_best_n", "Number of suggestions:",
                            value = 3, min = 1, max = 10, width = "100%")
              )
            ),
            fluidRow(
              column(12,
                actionButton("run_mapping", "Map Values to Ontology Terms",
                           icon = icon("magic"), class = "btn-primary btn-lg"),
                actionButton("apply_mapping", "Apply Selected Mappings",
                           icon = icon("check"), class = "btn-success"),
                actionButton("clear_mapping", "Clear Results",
                           icon = icon("eraser"), class = "btn-secondary")
              )
            ),
            hr(),
            uiOutput("mapping_status"),
            DTOutput("mapping_results")
          )
        ),
        
        # Cross-Ontology Mapping
        fluidRow(
          box(
            title = "Cross-Ontology Mapping (OxO)",
            status = "warning",
            solidHeader = TRUE,
            collapsible = TRUE,
            collapsed = TRUE,
            width = 12,
            icon = icon("exchange-alt"),
            p("Map ontology terms from one ontology to another using the OxO service."),
            fluidRow(
              column(4,
                selectInput("oxo_field", "Select field with ontology IDs:",
                           choices = NULL, width = "100%")
              ),
              column(4,
                selectInput("oxo_target", "Target ontology:",
                           choices = c("NCIT" = "NCIT",
                                     "EFO" = "EFO",
                                     "HP" = "HP",
                                     "MONDO" = "MONDO",
                                     "HANCESTRO" = "HANCESTRO"),
                           width = "100%")
              ),
              column(4,
                selectInput("oxo_distance", "Mapping distance:",
                           choices = c("1 (direct)" = 1,
                                     "2 (one hop)" = 2,
                                     "3 (two hops)" = 3),
                           selected = 1,
                           width = "100%")
              )
            ),
            actionButton("run_oxo", "Map Across Ontologies",
                        icon = icon("exchange-alt"), class = "btn-warning btn-lg"),
            hr(),
            uiOutput("oxo_status"),
            DTOutput("oxo_results")
          )
        ),
        
        # Bulk Operations
        fluidRow(
          box(
            title = "Bulk Operations",
            status = "success",
            solidHeader = TRUE,
            collapsible = TRUE,
            collapsed = TRUE,
            width = 6,
            icon = icon("tasks"),
            h5("Find and Replace"),
            fluidRow(
              column(12,
                selectInput("bulk_field", "Select field:",
                           choices = NULL, width = "100%")
              )
            ),
            fluidRow(
              column(6,
                textInput("find_text", "Find:", width = "100%")
              ),
              column(6,
                textInput("replace_text", "Replace with:", width = "100%")
              )
            ),
            checkboxInput("case_sensitive", "Case sensitive", value = FALSE),
            checkboxInput("whole_word", "Match whole word only", value = FALSE),
            actionButton("preview_replace", "Preview", 
                        icon = icon("eye"), class = "btn-info"),
            actionButton("apply_replace", "Apply Changes",
                        icon = icon("check"), class = "btn-success"),
            hr(),
            h5("Fill Down"),
            p("Fill empty cells with the value from the cell above."),
            selectInput("filldown_field", "Select field:",
                       choices = NULL, width = "100%"),
            actionButton("apply_filldown", "Fill Down Empty Cells",
                        icon = icon("arrow-down"), class = "btn-primary"),
            hr(),
            uiOutput("bulk_status")
          ),
          
          # Data Cleaning
          box(
            title = "Data Cleaning",
            status = "danger",
            solidHeader = TRUE,
            collapsible = TRUE,
            collapsed = TRUE,
            width = 6,
            icon = icon("broom"),
            h5("Text Cleaning Operations"),
            selectInput("clean_field", "Select field:",
                       choices = NULL, width = "100%"),
            checkboxGroupInput("clean_operations", "Select operations:",
                             choices = c(
                               "Trim whitespace" = "trim",
                               "Remove extra spaces" = "space",
                               "Convert to lowercase" = "lower",
                               "Convert to uppercase" = "upper",
                               "Title case" = "title",
                               "Remove special characters" = "special",
                               "Remove numbers" = "numbers"
                             ),
                             selected = c("trim", "space")),
            actionButton("preview_clean", "Preview Changes",
                        icon = icon("eye"), class = "btn-info"),
            actionButton("apply_clean", "Apply Cleaning",
                        icon = icon("broom"), class = "btn-danger"),
            hr(),
            h5("Remove Duplicates"),
            p("Remove duplicate rows based on selected fields."),
            selectInput("dedup_fields", "Select fields for comparison:",
                       choices = NULL, multiple = TRUE, width = "100%"),
            actionButton("apply_dedup", "Remove Duplicates",
                        icon = icon("filter"), class = "btn-warning"),
            hr(),
            uiOutput("clean_status")
          )
        ),
        
        # Curation Results
        fluidRow(
          box(
            title = "Curation Preview",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            icon = icon("clipboard-list"),
            uiOutput("curation_summary"),
            hr(),
            DTOutput("curation_preview")
          )
        )
      ),
      
      # Ontology Browser Tab
      tabItem(
        tabName = "ontology",
        fluidRow(
          box(
            title = "Schema Information",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            icon = icon("database"),
            fluidRow(
              column(3,
                div(class = "metric-card",
                    div(class = "metric-value", textOutput("schema_version_text")),
                    div(class = "metric-label", "Schema Version")
                )
              ),
              column(3,
                div(class = "metric-card",
                    div(class = "metric-value", textOutput("total_fields_text")),
                    div(class = "metric-label", "Total Fields")
                )
              ),
              column(3,
                div(class = "metric-card",
                    div(class = "metric-value", textOutput("required_fields_text")),
                    div(class = "metric-label", "Required Fields")
                )
              ),
              column(3,
                div(class = "metric-card",
                    div(class = "metric-value", textOutput("dynamic_enum_text")),
                    div(class = "metric-label", "Dynamic Enums")
                )
              )
            )
          )
        ),
        fluidRow(
          box(
            title = "Field Browser",
            status = "info",
            solidHeader = TRUE,
            width = 5,
            icon = icon("search"),
            textInput("field_search", "Search fields:", 
                     placeholder = "Type to search...", width = "100%"),
            selectInput("filter_category", "Filter by:",
                       choices = c("All Fields" = "all",
                                 "Required Only" = "required",
                                 "Optional Only" = "optional"),
                       width = "100%"),
            hr(),
            selectInput("schema_field_select", "Select Field:",
                       choices = all_fields, width = "100%")
          ),
          box(
            title = "Field Details",
            status = "success",
            solidHeader = TRUE,
            width = 7,
            icon = icon("info-circle"),
            uiOutput("schema_field_details")
          )
        ),
        fluidRow(
          box(
            title = "All Fields Reference",
            status = "warning",
            solidHeader = TRUE,
            collapsible = TRUE,
            width = 12,
            icon = icon("book"),
            DTOutput("schema_summary_table")
          )
        )
      ),
      
      # Export Tab
      tabItem(
        tabName = "export",
        fluidRow(
          box(
            title = "Export Data",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            icon = icon("file-export"),
            h4("Export Formats"),
            selectInput("export_format", "Choose format:",
                       choices = c("CSV (Comma-separated)" = "csv",
                                 "TSV (Tab-separated)" = "tsv",
                                 "JSON" = "json"),
                       width = "100%"),
            checkboxInput("export_validated_only", 
                         "Export only if validation passes", 
                         value = TRUE),
            hr(),
            downloadButton("download_export", "Download Export", 
                          class = "btn-success btn-lg btn-block")
          ),
          box(
            title = "Export Status",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            icon = icon("info-circle"),
            uiOutput("export_info")
          )
        )
      ),
      
      # Help Tab
      tabItem(
        tabName = "help",
        fluidRow(
          box(
            title = "Getting Started",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            h3("How to Use This App"),
            tags$ol(
              tags$li(tags$b("Dashboard:"), " View your project overview and quality metrics."),
              tags$li(tags$b("Import Data:"), " Load your CSV/TSV file or create a new template."),
              tags$li(tags$b("Edit Metadata:"), " Use the Data Editor to add/remove rows and columns, and edit cell values."),
              tags$li(tags$b("Quality Control:"), " Run validation to check for errors and warnings."),
              tags$li(tags$b("Ontology Browser:"), " View field definitions and requirements."),
              tags$li(tags$b("Export:"), " Download your curated and validated data.")
            ),
            hr(),
            h3("Required Fields"),
            p("The following fields are required and must be present:"),
            tags$ul(
              lapply(required_fields, function(f) tags$li(tags$code(f)))
            ),
            hr(),
            h3("Dynamic Enums"),
            p("Some fields use dynamic enums based on ontology hierarchies:"),
            tags$ul(
              tags$li(tags$b("ancestry:"), " Uses HANCESTRO ontology children"),
              tags$li(tags$b("ancestry_details:"), " Uses HANCESTRO ontology descendants"),
              tags$li("Check the Ontology Browser for specific ontology roots and properties")
            ),
            hr(),
            h3("Validation Tips"),
            tags$ul(
              tags$li("Errors indicate critical issues (e.g., missing required fields)"),
              tags$li("Warnings indicate potential issues (e.g., type mismatches, pattern violations)"),
              tags$li("Fix all errors before submitting your data"),
              tags$li("Review warnings and fix as appropriate")
            ),
            hr(),
            h3("Color Coding"),
            tags$ul(
              tags$li(tags$span(style = "background-color: #fff3e0; padding: 2px 5px; border-left: 3px solid #ff9800;", "Orange"), " = Required fields"),
              tags$li(tags$span(style = "background-color: #ffebee; padding: 2px 5px; border-left: 3px solid #f44336;", "Red"), " = Error fields"),
              tags$li(tags$span(style = "background-color: #fff9e6; padding: 2px 5px; border-left: 3px solid #ffc107;", "Yellow"), " = Warning fields"),
              tags$li(tags$span(style = "background-color: #e8f5e9; padding: 2px 5px; border-left: 3px solid #4caf50;", "Green"), " = Valid fields")
            )
          )
        )
      )
    )
  )
)

# Server Logic
server <- function(input, output, session) {
  
  # Reactive values
  rv <- reactiveValues(
    data = NULL,
    validation_results = NULL,
    selected_rows = NULL,
    mapping_results = NULL,
    oxo_results = NULL,
    curation_preview = NULL
  )
  
  # Navigation buttons
  observeEvent(input$goto_import, { updateTabItems(session, "tabs", "upload") })
  observeEvent(input$goto_editor, { updateTabItems(session, "tabs", "editor") })
  observeEvent(input$goto_validate, { updateTabItems(session, "tabs", "validation") })
  observeEvent(input$goto_export, { updateTabItems(session, "tabs", "export") })
  
  # Update column choices for adding new columns
  observe({
    available_fields <- if (is.null(rv$data)) {
      all_fields
    } else {
      setdiff(all_fields, colnames(rv$data))
    }
    updateSelectInput(session, "new_column_select", 
                     choices = c("Choose from schema..." = "", available_fields))
  })
  
  # Update field choices for curation tools
  observe({
    req(rv$data)
    field_choices <- colnames(rv$data)
    
    updateSelectInput(session, "map_field", choices = field_choices)
    updateSelectInput(session, "oxo_field", choices = field_choices)
    updateSelectInput(session, "bulk_field", choices = field_choices)
    updateSelectInput(session, "filldown_field", choices = field_choices)
    updateSelectInput(session, "clean_field", choices = field_choices)
    updateSelectInput(session, "dedup_fields", choices = field_choices)
  })
  
  # Dashboard value boxes
  output$vbox_samples <- renderValueBox({
    n_samples <- if(is.null(rv$data)) 0 else nrow(rv$data)
    valueBox(
      value = n_samples,
      subtitle = "Total Samples",
      icon = icon("flask"),
      color = "purple"
    )
  })
  
  output$vbox_fields <- renderValueBox({
    n_fields <- if(is.null(rv$data)) 0 else ncol(rv$data)
    valueBox(
      value = n_fields,
      subtitle = "Metadata Fields",
      icon = icon("columns"),
      color = "blue"
    )
  })
  
  output$vbox_completeness <- renderValueBox({
    if(is.null(rv$data)) {
      completeness <- 0
    } else {
      completeness <- round(mean(apply(rv$data, 2, function(x) 
        sum(!is.na(x) & x != "")) / nrow(rv$data)) * 100, 1)
    }
    valueBox(
      value = paste0(completeness, "%"),
      subtitle = "Completeness",
      icon = icon("chart-pie"),
      color = if(completeness >= 80) "green" else if(completeness >= 50) "yellow" else "red"
    )
  })
  
  output$vbox_quality <- renderValueBox({
    quality <- if(is.null(rv$validation_results)) {
      "Not Assessed"
    } else if(rv$validation_results$valid) {
      "Passed"
    } else {
      "Issues Found"
    }
    valueBox(
      value = quality,
      subtitle = "Quality Status",
      icon = icon("check-circle"),
      color = if(quality == "Passed") "green" else if(quality == "Not Assessed") "light-blue" else "red"
    )
  })
  
  # Completeness and validation plots
  output$completeness_plot <- renderPlot({
    if(is.null(rv$data)) {
      plot.new()
      text(0.5, 0.5, "No data loaded", cex = 1.5, col = "gray")
    } else {
      field_completeness <- apply(rv$data, 2, function(x) 
        sum(!is.na(x) & x != "") / length(x) * 100)
      
      par(mar = c(8, 4, 2, 1))
      top_fields <- sort(field_completeness, decreasing = TRUE)[1:min(10, length(field_completeness))]
      barplot(top_fields, 
              main = "Top 10 Field Completeness (%)",
              ylab = "Completeness %",
              col = ifelse(top_fields >= 80, "#4caf50", 
                    ifelse(top_fields >= 50, "#ffc107", "#f44336")),
              las = 2,
              cex.names = 0.7,
              ylim = c(0, 100))
    }
  })
  
  output$validation_plot <- renderPlot({
    if(is.null(rv$validation_results)) {
      plot.new()
      text(0.5, 0.5, "Run validation first", cex = 1.5, col = "gray")
    } else {
      counts <- c(
        Passed = if(rv$validation_results$valid && 
                   length(rv$validation_results$warnings) == 0) 1 else 0,
        Warnings = length(rv$validation_results$warnings),
        Errors = length(rv$validation_results$errors)
      )
      
      par(mar = c(4, 4, 2, 1))
      barplot(counts,
              main = "Validation Summary",
              col = c("#4caf50", "#ffc107", "#f44336"),
              ylab = "Count")
    }
  })
  
  # Schema metrics
  output$schema_version_text <- renderText({ schema$schema_info$version })
  output$total_fields_text <- renderText({ as.character(length(all_fields)) })
  output$required_fields_text <- renderText({ as.character(length(required_fields)) })
  output$dynamic_enum_text <- renderText({
    dynamic_count <- sum(sapply(all_fields, function(f) {
      field_def <- get_field_definition(schema, f)
      !is.null(field_def$ontology) && !is.null(field_def$ontology$roots)
    }))
    as.character(dynamic_count)
  })
  
  # Sidebar stats
  output$sidebar_stats <- renderUI({
    if (is.null(rv$data)) {
      tags$div(
        style = "color: #ddd;",
        p("No data loaded", style = "font-size: 13px;"),
        p("Import or create data to begin", style = "font-size: 11px;")
      )
    } else {
      req_present <- sum(required_fields %in% colnames(rv$data))
      completeness <- round(mean(apply(rv$data, 2, function(x) sum(!is.na(x) & x != "")) / nrow(rv$data)) * 100, 1)
      
      tags$div(
        style = "color: white;",
        tags$div(style = "background-color: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; margin-bottom: 8px;",
          tags$div(style = "font-size: 20px; font-weight: bold;", nrow(rv$data)),
          tags$div(style = "font-size: 11px; opacity: 0.9;", "Samples")
        ),
        tags$div(style = "background-color: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; margin-bottom: 8px;",
          tags$div(style = "font-size: 20px; font-weight: bold;", ncol(rv$data)),
          tags$div(style = "font-size: 11px; opacity: 0.9;", "Fields")
        ),
        tags$div(style = "background-color: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px; margin-bottom: 8px;",
          tags$div(style = "font-size: 20px; font-weight: bold;", 
                  paste0(req_present, "/", length(required_fields))),
          tags$div(style = "font-size: 11px; opacity: 0.9;", "Required")
        ),
        tags$div(style = "background-color: rgba(255,255,255,0.1); padding: 8px; border-radius: 4px;",
          tags$div(style = "font-size: 20px; font-weight: bold;", paste0(completeness, "%")),
          tags$div(style = "font-size: 11px; opacity: 0.9;", "Complete")
        )
      )
    }
  })
  
  # Load data from file
  observeEvent(input$load_data, {
    req(input$file_upload)
    
    tryCatch({
      rv$data <- read.delim(input$file_upload$datapath,
                           sep = input$sep,
                           header = input$header,
                           stringsAsFactors = FALSE,
                           check.names = FALSE)
      
      showNotification("Data loaded successfully!", type = "message")
      updateTabItems(session, "tabs", "dashboard")
    }, error = function(e) {
      showNotification(paste("Error loading file:", e$message), type = "error")
    })
  })
  
  # Create template
  observeEvent(input$create_template, {
    req(input$n_rows)
    
    # Create template with required fields
    template_data <- data.frame(matrix(NA, nrow = input$n_rows, 
                                      ncol = length(required_fields)))
    colnames(template_data) <- required_fields
    
    # Initialize with empty strings
    template_data[] <- lapply(template_data, function(x) rep("", input$n_rows))
    
    rv$data <- template_data
    showNotification("Template created! Add data and validate.", type = "message")
    updateTabItems(session, "tabs", "editor")
  })
  
  # Load demo data
  observeEvent(input$load_demo, {
    demo_file <- system.file("shiny/metadata_curation_app/demo_data.csv",
                            package = "OmicsMLRepoCuration")
    if(file.exists(demo_file)) {
      rv$data <- read.csv(demo_file, stringsAsFactors = FALSE)
      showNotification("Demo data loaded!", type = "message")
      updateTabItems(session, "tabs", "dashboard")
    } else {
      showNotification("Demo data not found.", type = "warning")
    }
  })
  
  # Upload summary and preview
  output$upload_summary <- renderUI({
    req(rv$data)
    tags$div(
      h4(paste("Loaded:", nrow(rv$data), "samples with", ncol(rv$data), "fields")),
      p(paste("Required fields present:", 
             sum(required_fields %in% colnames(rv$data)), "of", length(required_fields)))
    )
  })
  
  output$upload_preview <- renderDT({
    req(rv$data)
    datatable(head(rv$data, 100), 
             options = list(scrollX = TRUE, pageLength = 10),
             rownames = FALSE)
  })
  
  # Editor info
  output$editor_info <- renderUI({
    if(is.null(rv$data)) {
      tags$div(class = "alert alert-info",
        icon("info-circle"),
        " No data loaded. Import data or create a template to begin editing."
      )
    } else {
      tags$div(
        class = "alert alert-success",
        icon("check-circle"),
        paste(" Editing", nrow(rv$data), "samples with", ncol(rv$data), "fields")
      )
    }
  })
  
  # Data editor table
  output$data_table <- renderDT({
    req(rv$data)
    
    datatable(
      rv$data,
      editable = TRUE,
      selection = 'multiple',
      options = list(
        scrollX = TRUE,
        pageLength = 25,
        dom = 'Bfrtip'
      ),
      rownames = TRUE,
      class = 'cell-border stripe'
    ) %>%
      formatStyle(
        columns = which(colnames(rv$data) %in% required_fields),
        backgroundColor = '#fff3e0'
      )
  })
  
  # Handle cell edits
  observeEvent(input$data_table_cell_edit, {
    info <- input$data_table_cell_edit
    rv$data[info$row, info$col] <- info$value
  })
  
  # Track selected rows
  observe({
    rv$selected_rows <- input$data_table_rows_selected
  })
  
  # Add row
  observeEvent(input$add_row, {
    req(rv$data)
    
    new_row <- data.frame(matrix("", nrow = 1, ncol = ncol(rv$data)))
    colnames(new_row) <- colnames(rv$data)
    
    rv$data <- rbind(rv$data, new_row)
    showNotification("Sample added", type = "message")
  })
  
  # Delete row
  observeEvent(input$delete_row, {
    req(rv$data, rv$selected_rows)
    
    rv$data <- rv$data[-rv$selected_rows, , drop = FALSE]
    showNotification(paste("Deleted", length(rv$selected_rows), "sample(s)"), 
                    type = "warning")
  })
  
  # Duplicate row
  observeEvent(input$duplicate_row, {
    req(rv$data, rv$selected_rows)
    
    if(length(rv$selected_rows) > 0) {
      duplicated_rows <- rv$data[rv$selected_rows[1], , drop = FALSE]
      rv$data <- rbind(rv$data, duplicated_rows)
      showNotification("Sample duplicated", type = "message")
    }
  })
  
  # Add column
  observeEvent(input$confirm_add_column, {
    req(rv$data)
    
    new_col_name <- if (input$new_column_select != "") {
      input$new_column_select
    } else if (input$new_column_name != "") {
      input$new_column_name
    } else {
      return()
    }
    
    if (new_col_name %in% colnames(rv$data)) {
      showNotification("Field already exists!", type = "warning")
      return()
    }
    
    rv$data[[new_col_name]] <- ""
    showNotification(paste("Field", new_col_name, "added"), type = "message")
    
    # Reset inputs
    updateSelectInput(session, "new_column_select", selected = "")
    updateTextInput(session, "new_column_name", value = "")
  })
  
  # Download data
  output$download_data <- downloadHandler(
    filename = function() {
      paste0("curated_metadata_", Sys.Date(), ".csv")
    },
    content = function(file) {
      write.csv(rv$data, file, row.names = FALSE)
    }
  )
  
  # Run validation
  observeEvent(input$run_validation, {
    req(rv$data)
    
    withProgress(message = 'Validating data...', value = 0, {
      incProgress(0.3)
      
      rv$validation_results <- validate_data_against_schema(rv$data, schema)
      
      incProgress(0.7)
      
      showNotification("Validation complete!", type = "message")
    })
  })
  
  # Validate required fields only
  observeEvent(input$validate_required, {
    req(rv$data)
    
    missing <- setdiff(required_fields, colnames(rv$data))
    if(length(missing) > 0) {
      showNotification(paste("Missing required fields:", paste(missing, collapse = ", ")),
                      type = "error", duration = 10)
    } else {
      showNotification("All required fields present!", type = "message")
    }
  })
  
  # Validate types
  observeEvent(input$validate_types, {
    req(rv$data)
    
    type_issues <- c()
    for(col in colnames(rv$data)) {
      if(col %in% names(schema)) {
        field_def <- schema[[col]]
        if(field_def$col_class == "integer" && !is.numeric(rv$data[[col]])) {
          type_issues <- c(type_issues, paste(col, "should be numeric"))
        }
      }
    }
    
    if(length(type_issues) > 0) {
      showNotification(paste("Type issues:", paste(type_issues, collapse = "; ")),
                      type = "warning", duration = 10)
    } else {
      showNotification("All types look good!", type = "message")
    }
  })
  
  # Clear validation
  observeEvent(input$clear_validation, {
    rv$validation_results <- NULL
  })
  
  # Inline validation
  observeEvent(input$validate_inline, {
    req(rv$data)
    rv$validation_results <- validate_data_against_schema(rv$data, schema)
    updateTabItems(session, "tabs", "validation")
  })
  
  # Validation info boxes
  output$valid_box <- renderInfoBox({
    if (is.null(rv$validation_results)) {
      infoBox(
        "Status", "Not Run", icon = icon("question-circle"),
        color = "light-blue"
      )
    } else {
      infoBox(
        "Status", 
        if (rv$validation_results$valid) "PASSED" else "FAILED",
        icon = icon(if (rv$validation_results$valid) "check-circle" else "times-circle"),
        color = if (rv$validation_results$valid) "green" else "red"
      )
    }
  })
  
  output$error_box <- renderInfoBox({
    n_errors <- if (is.null(rv$validation_results)) {
      0
    } else {
      length(rv$validation_results$errors)
    }
    
    infoBox(
      "Errors", n_errors, icon = icon("exclamation-triangle"),
      color = if (n_errors > 0) "red" else "green"
    )
  })
  
  output$warning_box <- renderInfoBox({
    n_warnings <- if (is.null(rv$validation_results)) {
      0
    } else {
      length(rv$validation_results$warnings)
    }
    
    infoBox(
      "Warnings", n_warnings, icon = icon("exclamation-circle"),
      color = if (n_warnings > 0) "yellow" else "green"
    )
  })
  
  output$completeness_box <- renderInfoBox({
    if(is.null(rv$data)) {
      completeness <- 0
    } else {
      completeness <- round(mean(apply(rv$data, 2, function(x) 
        sum(!is.na(x) & x != "")) / nrow(rv$data)) * 100, 1)
    }
    
    infoBox(
      "Completeness", 
      paste0(completeness, "%"),
      icon = icon("chart-pie"),
      color = if(completeness >= 80) "green" else if(completeness >= 50) "yellow" else "red"
    )
  })
  
  # Validation results text
  output$validation_results <- renderPrint({
    req(rv$validation_results)
    
    cat("=== VALIDATION RESULTS ===\n\n")
    
    cat("Overall Status:", 
        if (rv$validation_results$valid) "✓ PASSED" else "✗ FAILED", "\n\n")
    
    if (length(rv$validation_results$errors) > 0) {
      cat("ERRORS:\n")
      for (i in seq_along(rv$validation_results$errors)) {
        cat(sprintf("  [%d] %s\n", i, rv$validation_results$errors[i]))
      }
      cat("\n")
    } else {
      cat("✓ No errors found\n\n")
    }
    
    if (length(rv$validation_results$warnings) > 0) {
      cat("WARNINGS:\n")
      for (i in seq_along(rv$validation_results$warnings)) {
        cat(sprintf("  [%d] %s\n", i, rv$validation_results$warnings[i]))
      }
      cat("\n")
    } else {
      cat("✓ No warnings\n\n")
    }
    
    if (rv$validation_results$valid && length(rv$validation_results$warnings) == 0) {
      cat("\n✓✓✓ Data is valid and ready for submission! ✓✓✓\n")
    }
  })
  
  # Issues summary
  output$issues_summary <- renderUI({
    if(is.null(rv$validation_results)) {
      tags$p("Run validation to see issues")
    } else {
      all_issues <- c(
        if(length(rv$validation_results$errors) > 0) 
          paste("ERROR:", rv$validation_results$errors),
        if(length(rv$validation_results$warnings) > 0) 
          paste("WARNING:", rv$validation_results$warnings)
      )
      
      if(length(all_issues) == 0) {
        tags$div(class = "alert alert-success",
          icon("check-circle"), " No issues found!"
        )
      } else {
        tags$div(
          tags$ul(
            lapply(all_issues, function(x) tags$li(x))
          )
        )
      }
    }
  })
  
  # Field validation table
  output$field_validation_table <- renderDT({
    req(rv$data)
    
    # Create field validation summary
    field_info <- lapply(colnames(rv$data), function(field) {
      in_schema <- field %in% all_fields
      is_required <- field %in% required_fields
      
      status <- if (!in_schema) {
        "Not in schema"
      } else if (is_required) {
        "Required"
      } else {
        "Optional"
      }
      
      # Count non-empty values
      non_empty <- sum(!is.na(rv$data[[field]]) & rv$data[[field]] != "")
      
      data.frame(
        Field = field,
        Status = status,
        NonEmpty = non_empty,
        Total = nrow(rv$data),
        PercentFilled = round(100 * non_empty / nrow(rv$data), 1),
        stringsAsFactors = FALSE
      )
    })
    
    field_df <- do.call(rbind, field_info)
    
    datatable(
      field_df,
      options = list(pageLength = 25, scrollX = TRUE),
      rownames = FALSE
    ) %>%
      formatStyle(
        'Status',
        backgroundColor = styleEqual(
          c('Required', 'Optional', 'Not in schema'),
          c('#fff3cd', '#d1ecf1', '#f8d7da')
        )
      ) %>%
      formatStyle(
        'PercentFilled',
        background = styleColorBar(c(0, 100), '#90EE90'),
        backgroundSize = '100% 90%',
        backgroundRepeat = 'no-repeat',
        backgroundPosition = 'center'
      )
  })
  
  # Schema field details
  output$schema_field_details <- renderUI({
    req(input$schema_field_select)
    
    field_def <- get_field_definition(schema, input$schema_field_select)
    
    tags$div(
      class = "field-card",
      h4(field_def$col_name),
      tags$p(tags$b("Type: "), field_def$col_class),
      tags$p(tags$b("Required: "), ifelse(field_def$required, "Yes", "No")),
      tags$p(tags$b("Multiple Values: "), ifelse(field_def$multiple_values, "Yes", "No")),
      tags$p(tags$b("Uniqueness: "), field_def$uniqueness),
      hr(),
      tags$p(tags$b("Description:")),
      tags$p(field_def$description),
      
      # Validation info
      if (!is.null(field_def$validation)) {
        tags$div(
          hr(),
          h5("Validation Rules:"),
          if (!is.null(field_def$validation$pattern)) {
            tags$p(tags$b("Pattern: "), tags$code(field_def$validation$pattern))
          },
          if (!is.null(field_def$validation$allowed_values)) {
            tags$div(
              tags$p(tags$b("Allowed Values: "), 
                    tags$span(class = "static-enum-badge", "Static Enum")),
              tags$ul(
                lapply(field_def$validation$allowed_values, function(v) tags$li(v))
              )
            )
          },
          if (!is.null(field_def$validation$delimiter)) {
            tags$p(tags$b("Delimiter: "), tags$code(field_def$validation$delimiter))
          }
        )
      },
      
      # Ontology info
      if (!is.null(field_def$ontology)) {
        tags$div(
          hr(),
          h5("Ontology Information:"),
          tags$span(class = "dynamic-enum-badge", "Dynamic Enum"),
          if (!is.null(field_def$ontology$roots)) {
            tags$div(
              tags$p(tags$b("Root Terms:")),
              tags$ul(
                lapply(field_def$ontology$roots, function(r) tags$li(tags$code(r)))
              )
            )
          },
          if (!is.null(field_def$ontology$property)) {
            tags$p(tags$b("Property: "), field_def$ontology$property)
          },
          if (!is.null(field_def$ontology$terms)) {
            tags$div(
              tags$p(tags$b("Ontology Terms:")),
              tags$ul(
                lapply(field_def$ontology$terms, function(t) tags$li(tags$code(t$id)))
              )
            )
          }
        )
      }
    )
  })
  
  # Schema summary table
  output$schema_summary_table <- renderDT({
    
    # Create summary for all fields
    summary_data <- lapply(all_fields, function(field) {
      field_def <- get_field_definition(schema, field)
      
      validation_type <- "None"
      if (!is.null(field_def$validation$allowed_values)) {
        validation_type <- "Static Enum"
      } else if (!is.null(field_def$validation$pattern)) {
        validation_type <- "Pattern"
      }
      
      if (!is.null(field_def$ontology)) {
        validation_type <- "Dynamic Enum"
      }
      
      data.frame(
        Field = field,
        Type = field_def$col_class,
        Required = ifelse(field_def$required, "Yes", "No"),
        MultiValue = ifelse(field_def$multiple_values, "Yes", "No"),
        Validation = validation_type,
        Description = substr(field_def$description, 1, 100),
        stringsAsFactors = FALSE
      )
    })
    
    summary_df <- do.call(rbind, summary_data)
    
    datatable(
      summary_df,
      options = list(
        pageLength = 25,
        scrollX = TRUE,
        dom = 'Bfrtip'
      ),
      rownames = FALSE,
      filter = 'top'
    ) %>%
      formatStyle(
        'Required',
        backgroundColor = styleEqual(c('Yes', 'No'), c('#fff3cd', 'white'))
      ) %>%
      formatStyle(
        'Validation',
        backgroundColor = styleEqual(
          c('Dynamic Enum', 'Static Enum', 'Pattern', 'None'),
          c('#d1ecf1', '#e2e3e5', '#d4edda', 'white')
        )
      )
  })
  
  # ========== DATA CURATION LOGIC ==========
  
  # Ontology Term Mapping
  observeEvent(input$run_mapping, {
    req(rv$data, input$map_field)
    
    withProgress(message = 'Mapping values to ontology...', value = 0, {
      incProgress(0.2)
      
      field_values <- unique(rv$data[[input$map_field]])
      field_values <- field_values[!is.na(field_values) & field_values != ""]
      
      if(length(field_values) == 0) {
        showNotification("No values to map in selected field", type = "warning")
        return()
      }
      
      incProgress(0.3)
      
      tryCatch({
        # Use mapNodes function from the package
        mapping_result <- mapNodes(
          col = field_values,
          onto = input$map_ontology,
          best_n = input$map_best_n
        )
        
        incProgress(0.8)
        
        # Format results for display
        results_list <- lapply(names(mapping_result), function(original_value) {
          suggestions <- mapping_result[[original_value]]
          if(length(suggestions) > 0) {
            data.frame(
              OriginalValue = original_value,
              SuggestedID = sapply(suggestions, function(x) x$id),
              SuggestedLabel = sapply(suggestions, function(x) x$label),
              Score = sapply(suggestions, function(x) round(x$score, 3)),
              stringsAsFactors = FALSE
            )
          } else {
            data.frame(
              OriginalValue = original_value,
              SuggestedID = "No match",
              SuggestedLabel = "No match",
              Score = 0,
              stringsAsFactors = FALSE
            )
          }
        })
        
        rv$mapping_results <- do.call(rbind, results_list)
        
        showNotification("Mapping completed successfully!", type = "message")
        
      }, error = function(e) {
        showNotification(paste("Mapping error:", e$message), type = "error")
      })
      
      incProgress(1)
    })
  })
  
  # Display mapping results
  output$mapping_results <- renderDT({
    req(rv$mapping_results)
    
    datatable(
      rv$mapping_results,
      selection = list(mode = 'multiple', target = 'row'),
      options = list(
        pageLength = 25,
        scrollX = TRUE
      ),
      rownames = FALSE
    ) %>%
      formatStyle(
        'Score',
        background = styleColorBar(c(0, 1), '#4caf50'),
        backgroundSize = '100% 90%',
        backgroundRepeat = 'no-repeat',
        backgroundPosition = 'center'
      )
  })
  
  output$mapping_status <- renderUI({
    if(is.null(rv$mapping_results)) {
      tags$p("No mapping results yet. Click 'Map Values' to begin.")
    } else {
      tags$div(
        class = "alert alert-info",
        icon("info-circle"),
        sprintf(" Found %d unique values, %d total mappings generated",
                length(unique(rv$mapping_results$OriginalValue)),
                nrow(rv$mapping_results))
      )
    }
  })
  
  # Apply selected mappings
  observeEvent(input$apply_mapping, {
    req(rv$data, rv$mapping_results, input$mapping_results_rows_selected)
    
    selected_mappings <- rv$mapping_results[input$mapping_results_rows_selected, ]
    
    # Apply mappings to data
    for(i in 1:nrow(selected_mappings)) {
      original <- selected_mappings$OriginalValue[i]
      mapped <- selected_mappings$SuggestedID[i]
      
      rv$data[[input$map_field]][rv$data[[input$map_field]] == original] <- mapped
    }
    
    showNotification(paste("Applied", nrow(selected_mappings), "mappings"), 
                    type = "message")
  })
  
  # Clear mapping results
  observeEvent(input$clear_mapping, {
    rv$mapping_results <- NULL
  })
  
  # Cross-Ontology Mapping (OxO)
  observeEvent(input$run_oxo, {
    req(rv$data, input$oxo_field)
    
    withProgress(message = 'Running OxO cross-ontology mapping...', value = 0, {
      incProgress(0.2)
      
      # Get unique ontology IDs from field
      term_ids <- unique(rv$data[[input$oxo_field]])
      term_ids <- term_ids[!is.na(term_ids) & term_ids != ""]
      
      # Filter for valid ontology ID format (e.g., "NCIT:C123")
      term_ids <- term_ids[grepl("^[A-Z]+:[A-Z0-9_]+$", term_ids)]
      
      if(length(term_ids) == 0) {
        showNotification("No valid ontology IDs found in selected field", 
                        type = "warning")
        return()
      }
      
      incProgress(0.3)
      
      tryCatch({
        # Use oxoMap function
        oxo_result <- oxoMap(
          term_ids = term_ids,
          target_ontology = input$oxo_target,
          mapping_distance = as.numeric(input$oxo_distance)
        )
        
        incProgress(0.8)
        
        # Format results
        results_list <- lapply(names(oxo_result), function(term) {
          mappings <- oxo_result[[term]]
          if(nrow(mappings) > 0) {
            data.frame(
              SourceID = term,
              TargetID = mappings$curie,
              TargetLabel = mappings$label,
              Distance = mappings$distance,
              stringsAsFactors = FALSE
            )
          } else {
            data.frame(
              SourceID = term,
              TargetID = "No mapping",
              TargetLabel = "No mapping",
              Distance = NA,
              stringsAsFactors = FALSE
            )
          }
        })
        
        rv$oxo_results <- do.call(rbind, results_list)
        
        showNotification("OxO mapping completed!", type = "message")
        
      }, error = function(e) {
        showNotification(paste("OxO mapping error:", e$message), type = "error")
      })
      
      incProgress(1)
    })
  })
  
  # Display OxO results
  output$oxo_results <- renderDT({
    req(rv$oxo_results)
    
    datatable(
      rv$oxo_results,
      options = list(
        pageLength = 25,
        scrollX = TRUE
      ),
      rownames = FALSE
    ) %>%
      formatStyle(
        'Distance',
        backgroundColor = styleEqual(c(1, 2, 3), c('#d4edda', '#fff3cd', '#f8d7da'))
      )
  })
  
  output$oxo_status <- renderUI({
    if(is.null(rv$oxo_results)) {
      tags$p("No OxO results yet. Click 'Map Across Ontologies' to begin.")
    } else {
      tags$div(
        class = "alert alert-success",
        icon("check-circle"),
        sprintf(" Mapped %d source terms, found %d target mappings",
                length(unique(rv$oxo_results$SourceID)),
                sum(rv$oxo_results$TargetID != "No mapping"))
      )
    }
  })
  
  # Find and Replace - Preview
  observeEvent(input$preview_replace, {
    req(rv$data, input$bulk_field, input$find_text)
    
    field_data <- rv$data[[input$bulk_field]]
    
    if(input$case_sensitive) {
      matches <- grepl(input$find_text, field_data, fixed = !input$whole_word)
    } else {
      matches <- grepl(input$find_text, field_data, fixed = !input$whole_word, 
                      ignore.case = TRUE)
    }
    
    n_matches <- sum(matches, na.rm = TRUE)
    
    showNotification(
      paste("Found", n_matches, "matches in", input$bulk_field),
      type = if(n_matches > 0) "message" else "warning",
      duration = 5
    )
  })
  
  # Find and Replace - Apply
  observeEvent(input$apply_replace, {
    req(rv$data, input$bulk_field, input$find_text)
    
    field_data <- rv$data[[input$bulk_field]]
    
    if(input$case_sensitive) {
      if(input$whole_word) {
        pattern <- paste0("\\b", input$find_text, "\\b")
        rv$data[[input$bulk_field]] <- gsub(pattern, input$replace_text, field_data)
      } else {
        rv$data[[input$bulk_field]] <- gsub(input$find_text, input$replace_text, 
                                            field_data, fixed = TRUE)
      }
    } else {
      if(input$whole_word) {
        pattern <- paste0("\\b", input$find_text, "\\b")
        rv$data[[input$bulk_field]] <- gsub(pattern, input$replace_text, 
                                            field_data, ignore.case = TRUE)
      } else {
        rv$data[[input$bulk_field]] <- gsub(input$find_text, input$replace_text, 
                                            field_data, ignore.case = TRUE, fixed = FALSE)
      }
    }
    
    showNotification("Replacement applied successfully!", type = "message")
  })
  
  # Fill Down
  observeEvent(input$apply_filldown, {
    req(rv$data, input$filldown_field)
    
    field_data <- rv$data[[input$filldown_field]]
    
    # Fill down logic: propagate last non-empty value
    for(i in 2:length(field_data)) {
      if(is.na(field_data[i]) || field_data[i] == "") {
        field_data[i] <- field_data[i-1]
      }
    }
    
    rv$data[[input$filldown_field]] <- field_data
    
    showNotification("Fill down completed!", type = "message")
  })
  
  output$bulk_status <- renderUI({
    if(is.null(rv$data)) {
      tags$p("Load data to use bulk operations")
    } else {
      tags$div(
        class = "alert alert-success",
        icon("check-circle"),
        " Data loaded. Select operations above."
      )
    }
  })
  
  # Data Cleaning - Preview
  observeEvent(input$preview_clean, {
    req(rv$data, input$clean_field, input$clean_operations)
    
    field_data <- rv$data[[input$clean_field]]
    cleaned <- field_data
    
    for(op in input$clean_operations) {
      cleaned <- switch(op,
        "trim" = trimws(cleaned),
        "space" = gsub("\\s+", " ", cleaned),
        "lower" = tolower(cleaned),
        "upper" = toupper(cleaned),
        "title" = tools::toTitleCase(cleaned),
        "special" = gsub("[^[:alnum:][:space:]]", "", cleaned),
        "numbers" = gsub("[0-9]", "", cleaned),
        cleaned
      )
    }
    
    # Show preview of changes
    changes <- sum(field_data != cleaned, na.rm = TRUE)
    
    rv$curation_preview <- data.frame(
      Original = head(field_data[field_data != cleaned], 10),
      Cleaned = head(cleaned[field_data != cleaned], 10),
      stringsAsFactors = FALSE
    )
    
    showNotification(
      paste("Preview:", changes, "values will be changed"),
      type = "message",
      duration = 5
    )
  })
  
  # Data Cleaning - Apply
  observeEvent(input$apply_clean, {
    req(rv$data, input$clean_field, input$clean_operations)
    
    field_data <- rv$data[[input$clean_field]]
    cleaned <- field_data
    
    for(op in input$clean_operations) {
      cleaned <- switch(op,
        "trim" = trimws(cleaned),
        "space" = gsub("\\s+", " ", cleaned),
        "lower" = tolower(cleaned),
        "upper" = toupper(cleaned),
        "title" = tools::toTitleCase(cleaned),
        "special" = gsub("[^[:alnum:][:space:]]", "", cleaned),
        "numbers" = gsub("[0-9]", "", cleaned),
        cleaned
      )
    }
    
    rv$data[[input$clean_field]] <- cleaned
    
    showNotification("Cleaning applied successfully!", type = "message")
  })
  
  # Remove Duplicates
  observeEvent(input$apply_dedup, {
    req(rv$data, input$dedup_fields)
    
    original_rows <- nrow(rv$data)
    
    rv$data <- rv$data %>%
      distinct(across(all_of(input$dedup_fields)), .keep_all = TRUE)
    
    removed <- original_rows - nrow(rv$data)
    
    showNotification(
      paste("Removed", removed, "duplicate rows"),
      type = if(removed > 0) "message" else "warning",
      duration = 5
    )
  })
  
  output$clean_status <- renderUI({
    if(is.null(rv$data)) {
      tags$p("Load data to use cleaning tools")
    } else {
      tags$div(
        class = "alert alert-info",
        icon("info-circle"),
        " Select field and operations above"
      )
    }
  })
  
  # Curation Preview Output
  output$curation_preview <- renderDT({
    if(!is.null(rv$curation_preview)) {
      datatable(
        rv$curation_preview,
        options = list(pageLength = 10, scrollX = TRUE),
        rownames = FALSE
      )
    } else {
      datatable(
        data.frame(Message = "No preview available"),
        options = list(dom = 't'),
        rownames = FALSE
      )
    }
  })
  
  output$curation_summary <- renderUI({
    if(!is.null(rv$curation_preview)) {
      tags$div(
        class = "alert alert-warning",
        icon("eye"),
        sprintf(" Preview showing changes (up to 10 samples)")
      )
    } else {
      tags$p("Preview will appear here when you use curation tools")
    }
  })
  
  # ========== END DATA CURATION LOGIC ==========
  
  # Export info
  output$export_info <- renderUI({
    if(is.null(rv$data)) {
      tags$div(class = "alert alert-warning",
        icon("exclamation-triangle"),
        " No data to export. Load or create data first."
      )
    } else {
      validation_status <- if(is.null(rv$validation_results)) {
        "Not validated"
      } else if(rv$validation_results$valid) {
        "Passed validation"
      } else {
        "Failed validation"
      }
      
      tags$div(
        h4("Export Ready"),
        tags$p(paste("Samples:", nrow(rv$data))),
        tags$p(paste("Fields:", ncol(rv$data))),
        tags$p(paste("Status:", validation_status)),
        hr(),
        if(input$export_validated_only && !is.null(rv$validation_results) && !rv$validation_results$valid) {
          tags$div(class = "alert alert-danger",
            icon("times-circle"),
            " Cannot export: validation failed. Uncheck 'export only if validated' or fix errors."
          )
        } else {
          tags$div(class = "alert alert-success",
            icon("check-circle"),
            " Ready to export!"
          )
        }
      )
    }
  })
  
  # Download export
  output$download_export <- downloadHandler(
    filename = function() {
      ext <- switch(input$export_format,
                   "csv" = ".csv",
                   "tsv" = ".tsv",
                   "json" = ".json")
      paste0("metadata_export_", Sys.Date(), ext)
    },
    content = function(file) {
      req(rv$data)
      
      # Check validation if required
      if(input$export_validated_only && !is.null(rv$validation_results) && !rv$validation_results$valid) {
        showNotification("Cannot export: validation failed", type = "error")
        return()
      }
      
      switch(input$export_format,
        "csv" = write.csv(rv$data, file, row.names = FALSE),
        "tsv" = write.table(rv$data, file, sep = "\t", row.names = FALSE, quote = FALSE),
        "json" = write(toJSON(rv$data, pretty = TRUE), file)
      )
    }
  )
}

# Run the app
shinyApp(ui = ui, server = server)
