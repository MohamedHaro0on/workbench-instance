#!/usr/bin/env Rscript
# ============================================
# R Package Installation Script
# Handles archived packages (tibbletime)
# ============================================

# Configuration
install_repo <- "https://cloud.r-project.org"
lib_path <- "/usr/local/lib/R/site-library"
ncpus <- parallel::detectCores()

options(
  repos = c(CRAN = install_repo),
  warn = 1
)

cat("============================================\n")
cat("R Package Installation\n")
cat("Using", ncpus, "CPU cores\n")
cat("============================================\n\n")

# Helper function to install a package
install_pkg <- function(pkg, from_archive = FALSE, archive_url = NULL) {
  cat("\n>>> Installing:", pkg, "\n")
  
  tryCatch({
    if (!requireNamespace(pkg, quietly = TRUE)) {
      if (from_archive && !is.null(archive_url)) {
        cat("    Installing from CRAN Archive...\n")
        install.packages(archive_url, repos = NULL, type = "source",
                         lib = lib_path, Ncpus = ncpus)
      } else {
        install.packages(pkg, lib = lib_path, repos = install_repo,
                         dependencies = TRUE, Ncpus = ncpus)
      }
    } else {
      cat("    Already installed\n")
    }
    
    # Verify
    if (requireNamespace(pkg, quietly = TRUE)) {
      ver <- as.character(packageVersion(pkg))
      cat("    SUCCESS:", pkg, ver, "\n")
      return(TRUE)
    } else {
      cat("    FAILED:", pkg, "\n")
      return(FALSE)
    }
  }, error = function(e) {
    cat("    ERROR:", conditionMessage(e), "\n")
    return(FALSE)
  })
}

# ============================================
# PHASE 1: Install core dependencies first
# ============================================
cat("\n=== PHASE 1: Core Dependencies ===\n")

core_packages <- c(
  "rlang", "cli", "glue", "vctrs", "lifecycle", "pillar",
  "Rcpp", "R6", "magrittr", "fansi", "utf8", "pkgconfig"
)

for (pkg in core_packages) {
  install_pkg(pkg)
}

# ============================================
# PHASE 2: Data manipulation packages
# ============================================
cat("\n=== PHASE 2: Data Manipulation ===\n")

data_packages <- c("tibble", "dplyr", "tidyr", "purrr", "readr", "stringr", "forcats")

for (pkg in data_packages) {
  install_pkg(pkg)
}

# ============================================
# PHASE 3: Visualization and utilities
# ============================================
cat("\n=== PHASE 3: Visualization & Utilities ===\n")

viz_packages <- c("ggplot2", "scales", "data.table", "jsonlite", "lubridate")

for (pkg in viz_packages) {
  install_pkg(pkg)
}

# ============================================
# PHASE 4: Parallel processing
# ============================================
cat("\n=== PHASE 4: Parallel Processing ===\n")

parallel_packages <- c("foreach", "iterators", "doParallel", "pbapply")

for (pkg in parallel_packages) {
  install_pkg(pkg)
}

# ============================================
# PHASE 5: plyr (legacy, but requested)
# ============================================
cat("\n=== PHASE 5: plyr ===\n")
install_pkg("plyr")

# ============================================
# PHASE 6: Time series packages
# ============================================
cat("\n=== PHASE 6: Time Series ===\n")

ts_packages <- c("zoo", "xts", "tseries", "forecast", "TTR", "quantmod")

for (pkg in ts_packages) {
  install_pkg(pkg)
}

# ============================================
# PHASE 7: timetk dependencies and timetk
# ============================================
cat("\n=== PHASE 7: timetk ===\n")

timetk_deps <- c("timeDate", "padr", "anytime", "slider")

for (pkg in timetk_deps) {
  install_pkg(pkg)
}

install_pkg("timetk")

# ============================================
# PHASE 8: sweep
# ============================================
cat("\n=== PHASE 8: sweep ===\n")

# sweep might also be archived, try installing
tryCatch({
  install_pkg("sweep")
}, error = function(e) {
  cat("Trying sweep from archive...\n")
  install_pkg("sweep", from_archive = TRUE,
              archive_url = "https://cran.r-project.org/src/contrib/Archive/sweep/sweep_0.2.5.tar.gz")
})

# ============================================
# PHASE 9: tibbletime (ARCHIVED - must install from archive)
# ============================================
cat("\n=== PHASE 9: tibbletime (from CRAN Archive) ===\n")

# tibbletime was archived on 2022-10-25
# Latest version: 0.1.8
tibbletime_url <- "https://cran.r-project.org/src/contrib/Archive/tibbletime/tibbletime_0.1.8.tar.gz"

if (!requireNamespace("tibbletime", quietly = TRUE)) {
  cat("Installing tibbletime from CRAN Archive...\n")
  tryCatch({
    install.packages(tibbletime_url, repos = NULL, type = "source",
                     lib = lib_path, Ncpus = ncpus)
    if (requireNamespace("tibbletime", quietly = TRUE)) {
      cat("SUCCESS: tibbletime", as.character(packageVersion("tibbletime")), "\n")
    }
  }, error = function(e) {
    cat("ERROR installing tibbletime:", conditionMessage(e), "\n")
  })
} else {
  cat("tibbletime already installed\n")
}

# ============================================
# PHASE 10: anomalize (depends on tibbletime)
# ============================================
cat("\n=== PHASE 10: anomalize ===\n")

# First ensure all anomalize dependencies are present
anomalize_deps <- c("assertthat", "ggfortify", "tidyverse")

for (pkg in anomalize_deps) {
  install_pkg(pkg)
}

# Now install anomalize
if (requireNamespace("tibbletime", quietly = TRUE)) {
  install_pkg("anomalize")
} else {
  cat("ERROR: Cannot install anomalize - tibbletime is missing\n")
}

# ============================================
# PHASE 11: IRkernel
# ============================================
cat("\n=== PHASE 11: IRkernel ===\n")

irkernel_deps <- c("repr", "IRdisplay", "evaluate", "crayon", "pbdZMQ", "uuid")

for (pkg in irkernel_deps) {
  install_pkg(pkg)
}

install_pkg("IRkernel")

# ============================================
# FINAL: Verification
# ============================================
cat("\n============================================\n")
cat("INSTALLATION COMPLETE - VERIFICATION\n")
cat("============================================\n\n")

# Client requested packages
client_packages <- c(
  "plyr",
  "anomalize", 
  "foreach",
  "tidyverse",
  "tibbletime",
  "doParallel",  # parallel backend (parallel is base R)
  "pbapply",
  "dplyr"
)

cat("Client Requested Packages:\n")
cat("--------------------------------------------\n")

all_ok <- TRUE
for (pkg in client_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    ver <- as.character(packageVersion(pkg))
    cat(sprintf("  ✓ %-15s %s\n", pkg, ver))
  } else {
    cat(sprintf("  ✗ %-15s MISSING\n", pkg))
    all_ok <- FALSE
  }
}

# Check parallel (base R package)
cat(sprintf("  ✓ %-15s (base R)\n", "parallel"))

cat("--------------------------------------------\n")

if (!all_ok) {
  cat("\nWARNING: Some packages failed to install!\n")
  quit(status = 1)
} else {
  cat("\nAll client packages installed successfully!\n")
}

# Total packages installed
installed <- installed.packages(lib.loc = lib_path)
cat("\nTotal packages in library:", nrow(installed), "\n")