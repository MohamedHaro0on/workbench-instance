#!/usr/bin/env Rscript
# ============================================
# R Package Installation Script
# Fixed for Alpine/musl compilation
# ============================================

# Configuration
install_repo <- "https://cloud.r-project.org"
lib_path <- "/usr/local/lib/R/site-library"
ncpus <- parallel::detectCores()

options(
  repos = c(CRAN = install_repo),
  warn = 1,
  Ncpus = ncpus
)

cat("============================================\n")
cat("R Package Installation for Alpine\n")
cat("Using", ncpus, "CPU cores\n")
cat("Library path:", lib_path, "\n")
cat("============================================\n\n")

# Helper function to install a package
install_pkg <- function(pkg, from_url = NULL) {
  cat("\n>>> Installing:", pkg, "\n")
  
  tryCatch({
    if (!is.null(from_url)) {
      # Install from URL (for archived packages)
      cat("    Source:", from_url, "\n")
      install.packages(from_url, repos = NULL, type = "source",
                       lib = lib_path, Ncpus = ncpus, quiet = FALSE)
    } else if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(pkg, lib = lib_path, repos = install_repo,
                       dependencies = TRUE, Ncpus = ncpus, quiet = FALSE)
    } else {
      cat("    Already installed\n")
    }
    
    # Verify installation
    if (requireNamespace(pkg, quietly = TRUE)) {
      ver <- as.character(packageVersion(pkg))
      cat("    SUCCESS:", pkg, ver, "\n")
      return(TRUE)
    } else {
      cat("    FAILED to verify:", pkg, "\n")
      return(FALSE)
    }
  }, error = function(e) {
    cat("    ERROR:", conditionMessage(e), "\n")
    return(FALSE)
  })
}

# ============================================
# PHASE 1: Core dependencies
# ============================================
cat("\n=== PHASE 1: Core Dependencies ===\n")
core_pkgs <- c("rlang", "cli", "glue", "vctrs", "lifecycle", "pillar",
               "Rcpp", "R6", "magrittr", "fansi", "utf8", "pkgconfig")
for (pkg in core_pkgs) install_pkg(pkg)

# ============================================
# PHASE 2: Data manipulation
# ============================================
cat("\n=== PHASE 2: Data Manipulation ===\n")
data_pkgs <- c("tibble", "dplyr", "tidyr", "purrr", "readr", "stringr", "forcats")
for (pkg in data_pkgs) install_pkg(pkg)

# ============================================
# PHASE 3: plyr and data.table
# ============================================
cat("\n=== PHASE 3: plyr & data.table ===\n")
install_pkg("plyr")
install_pkg("data.table")

# ============================================
# PHASE 4: Visualization
# ============================================
cat("\n=== PHASE 4: Visualization ===\n")
install_pkg("ggplot2")
install_pkg("scales")

# ============================================
# PHASE 5: Utilities
# ============================================
cat("\n=== PHASE 5: Utilities ===\n")
util_pkgs <- c("jsonlite", "lubridate", "hms", "withr", "crayon")
for (pkg in util_pkgs) install_pkg(pkg)

# ============================================
# PHASE 6: Parallel processing
# ============================================
cat("\n=== PHASE 6: Parallel Processing ===\n")
parallel_pkgs <- c("foreach", "iterators", "doParallel", "pbapply")
for (pkg in parallel_pkgs) install_pkg(pkg)

# ============================================
# PHASE 7: Time series base
# ============================================
cat("\n=== PHASE 7: Time Series Base ===\n")
ts_pkgs <- c("zoo", "xts", "tseries", "TTR", "quantmod")
for (pkg in ts_pkgs) install_pkg(pkg)

# ============================================
# PHASE 8: forecast
# ============================================
cat("\n=== PHASE 8: forecast ===\n")
install_pkg("forecast")

# ============================================
# PHASE 9: timetk dependencies
# ============================================
cat("\n=== PHASE 9: timetk ===\n")
timetk_deps <- c("timeDate", "anytime", "padr", "slider", "recipes")
for (pkg in timetk_deps) install_pkg(pkg)
install_pkg("timetk")

# ============================================
# PHASE 10: sweep (may be archived)
# ============================================
cat("\n=== PHASE 10: sweep ===\n")
sweep_installed <- install_pkg("sweep")
if (!sweep_installed) {
  cat("    Trying sweep from CRAN Archive...\n")
  install_pkg("sweep", from_url = "https://cran.r-project.org/src/contrib/Archive/sweep/sweep_0.2.5.tar.gz")
}

# ============================================
# PHASE 11: tibbletime (ARCHIVED)
# ============================================
cat("\n=== PHASE 11: tibbletime (CRAN Archive) ===\n")
if (!requireNamespace("tibbletime", quietly = TRUE)) {
  install_pkg("tibbletime", from_url = "https://cran.r-project.org/src/contrib/Archive/tibbletime/tibbletime_0.1.8.tar.gz")
}

# ============================================
# PHASE 12: tidyverse meta-package
# ============================================
cat("\n=== PHASE 12: tidyverse ===\n")
install_pkg("tidyverse")

# ============================================
# PHASE 13: anomalize
# ============================================
cat("\n=== PHASE 13: anomalize ===\n")
anomalize_deps <- c("assertthat", "ggfortify", "cowplot")
for (pkg in anomalize_deps) install_pkg(pkg)
install_pkg("anomalize")

# ============================================
# PHASE 14: IRkernel dependencies
# ============================================
cat("\n=== PHASE 14: IRkernel Dependencies ===\n")
irkernel_deps <- c("repr", "IRdisplay", "evaluate", "digest")
for (pkg in irkernel_deps) install_pkg(pkg)

# Install pbdZMQ with special handling for Alpine
cat("\n>>> Installing: pbdZMQ (with Alpine fixes)\n")
tryCatch({
  if (!requireNamespace("pbdZMQ", quietly = TRUE)) {
    # Set environment for zmq
    Sys.setenv(ZMQ_INCLUDE = "/usr/include")
    Sys.setenv(ZMQ_LIB = "/usr/lib")
    install.packages("pbdZMQ", lib = lib_path, repos = install_repo,
                     configure.args = "--with-zmq-include=/usr/include --with-zmq-lib=/usr/lib",
                     Ncpus = ncpus)
  }
  if (requireNamespace("pbdZMQ", quietly = TRUE)) {
    cat("    SUCCESS: pbdZMQ\n")
  }
}, error = function(e) {
  cat("    ERROR pbdZMQ:", conditionMessage(e), "\n")
})

# Install uuid with special handling
cat("\n>>> Installing: uuid\n")
tryCatch({
  if (!requireNamespace("uuid", quietly = TRUE)) {
    Sys.setenv(PKG_CFLAGS = "-I/usr/include")
    Sys.setenv(PKG_LIBS = "-L/usr/lib -luuid")
    install.packages("uuid", lib = lib_path, repos = install_repo, Ncpus = ncpus)
  }
  if (requireNamespace("uuid", quietly = TRUE)) {
    cat("    SUCCESS: uuid\n")
  }
}, error = function(e) {
  cat("    ERROR uuid:", conditionMessage(e), "\n")
})

# ============================================
# PHASE 15: IRkernel
# ============================================
cat("\n=== PHASE 15: IRkernel ===\n")
install_pkg("IRkernel")

# ============================================
# FINAL VERIFICATION
# ============================================
cat("\n============================================\n")
cat("FINAL VERIFICATION\n")
cat("============================================\n\n")

client_packages <- c(
  "plyr", "anomalize", "foreach", "tidyverse",
  "tibbletime", "doParallel", "pbapply", "dplyr", "IRkernel"
)

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
cat(sprintf("  ✓ %-15s (base R)\n", "parallel"))

cat("\n--------------------------------------------\n")

# Count total packages
installed <- installed.packages(lib.loc = lib_path)
cat("Total packages installed:", nrow(installed), "\n")

if (!all_ok) {
  cat("\nWARNING: Some packages failed to install!\n")
  cat("The build will continue, but some features may not work.\n")
  # Don't exit with error - let Docker verify step catch it
}

cat("\nR package installation completed.\n")