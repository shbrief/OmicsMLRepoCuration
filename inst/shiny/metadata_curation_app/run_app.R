#!/usr/bin/env Rscript
#
# Example script to launch the Metadata Curation Shiny App
# OmicsMLRepoCuration Package
#

# Load the package
library(OmicsMLRepoCuration)

# Launch the app
# This will open in your default web browser
launch_curation_app()

# Alternative options:
#
# Launch in RStudio viewer pane:
# launch_curation_app(launch.browser = FALSE)
#
# Launch on specific port:
# launch_curation_app(port = 3838)
#
# Launch on network (accessible from other computers):
# launch_curation_app(host = "0.0.0.0", port = 8080)
