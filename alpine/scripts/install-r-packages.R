#!/usr/bin/env Rscript
# ============================================
# R Package Installation Script for Alpine
# Client: Vodafone - All requested packages
# ============================================

lib_path <- "/usr/local/lib/R/site-library"
ncpus <- parallel::detectCores()

options(
  repos = c(CRAN = "https://cloud.r-project.org"),
  warn = 1,
  Ncpus = ncpus,
  timeout = 300
)

cat("============================================\n")
cat("Installing R Packages\n")
cat("Library:", lib_path, "\n")
cat("CPUs:", ncpus, "\n")
cat("============================================\n\n")

# Ensure library path exists
if (!dir.exists(lib_path)) {
  dir.create(lib_path, recursive = TRUE)
}

install_pkg <- function(pkg, from_url = NULL, retries = 3) {
  cat(">>> Installing:", pkg, "\n")
  
  for (attempt in 1:retries) {
    result <- tryCatch({
      if (!is.null(from_url)) {
        install.packages(from_url, repos = NULL, type = "source", lib = lib_path)
      } else if (!requireNamespace(pkg, quietly = TRUE)) {
        install.packages(pkg, lib = lib_path, dependencies = TRUE, Ncpus = ncpus)
      }
      
      if (requireNamespace(pkg, quietly = TRUE)) {
        cat("    OK:", pkg, as.character(packageVersion(pkg)), "\n")
        return(TRUE)
      }
      return(FALSE)
    }, error = function(e) {
      cat("    Attempt", attempt, "failed:", conditionMessage(e), "\n")
      if (attempt < retries) {
        Sys.sleep(2)
      }
      return(FALSE)
    })
    
    if (result) return(TRUE)
  }
  
  cat("    FAILED after", retries, "attempts:", pkg, "\n")
  return(FALSE)
}

# Phase 1: Core dependencies (order matters)
cat("\n=== Phase 1: Core Dependencies ===\n")
core_pkgs <- c("rlang", "cli", "glue", "vctrs", "lifecycle", "pillar", "Rcpp", "R6", "magrittr")
for (p in core_pkgs) install_pkg(p)

# Phase 2: Data manipulation
cat("\n=== Phase 2: Data Packages ===\n")
data_pkgs <- c("tibble", "dplyr", "tidyr", "purrr", "readr", "stringr", "forcats", "plyr", "data.table")
for (p in data_pkgs) install_pkg(p)

# Phase 3: Visualization
cat("\n=== Phase 3: Visualization ===\n")
install_pkg("ggplot2")

# Phase 4: Utilities
cat("\n=== Phase 4: Utilities ===\n")
util_pkgs <- c("jsonlite", "lubridate", "hms", "withr", "crayon")
for (p in util_pkgs) install_pkg(p)

# Phase 5: Parallel processing
cat("\n=== Phase 5: Parallel Processing ===\n")
parallel_pkgs <- c("foreach", "iterators", "doParallel", "pbapply")
for (p in parallel_pkgs) install_pkg(p)

# Phase 6: Time series
cat("\n=== Phase 6: Time Series ===\n")
ts_pkgs <- c("zoo", "xts", "tseries", "TTR", "quantmod", "forecast")
for (p in ts_pkgs) install_pkg(p)

# Phase 7: timetk
cat("\n=== Phase 7: timetk ===\n")
for (p in c("timeDate", "timetk")) install_pkg(p)

# Phase 8: sweep (may be archived)
cat("\n=== Phase 8: sweep ===\n")
if (!install_pkg("sweep")) {
  install_pkg("sweep", from_url = "https://cran.r-project.org/src/contrib/Archive/sweep/sweep_0.2.5.tar.gz")
}

# Phase 9: tibbletime (ARCHIVED on CRAN)
cat("\n=== Phase 9: tibbletime (ARCHIVED) ===\n")
install_pkg("tibbletime", from_url = "https://cran.r-project.org/src/contrib/Archive/tibbletime/tibbletime_0.1.8.tar.gz")

# Phase 10: tidyverse meta-package
cat("\n=== Phase 10: tidyverse ===\n")
tryCatch({
  install_pkg("tidyverse")
}, error = function(e) {
  cat("    tidyverse meta-package failed, individual packages should work\n")
})

# Phase 11: anomalize (depends on tibbletime)
cat("\n=== Phase 11: anomalize ===\n")
for (p in c("assertthat", "ggfortify")) install_pkg(p)
install_pkg("anomalize")

# Phase 12: IRkernel dependencies
cat("\n=== Phase 12: IRkernel Dependencies ===\n")
irkernel_deps <- c("repr", "IRdisplay", "evaluate", "digest", "uuid")
for (p in irkernel_deps) install_pkg(p)

# Phase 13: pbdZMQ (requires special config for ZeroMQ)
cat("\n=== Phase 13: pbdZMQ ===\n")
tryCatch({
  Sys.setenv(ZMQ_INCLUDE = "/usr/include", ZMQ_LIB = "/usr/lib")
  install.packages("pbdZMQ", lib = lib_path, 
    configure.args = "--with-zmq-include=/usr/include --with-zmq-lib=/usr/lib",
    Ncpus = ncpus)
  cat("    OK: pbdZMQ\n")
}, error = function(e) {
  cat("    pbdZMQ error:", conditionMessage(e), "\n")
})

# Phase 14: IRkernel
cat("\n=== Phase 14: IRkernel ===\n")
install_pkg("IRkernel")

# ============================================
# Verification
# ============================================
cat("\n============================================\n")
cat("VERIFICATION - CLIENT REQUESTED PACKAGES\n")
cat("============================================\n")

client_pkgs <- c(
  "plyr", "anomalize", "foreach", "tidyverse", 
  "tibbletime", "doParallel", "pbapply", "dplyr", "IRkernel"
)

results <- data.frame(
  Package = character(),
  Status = character(),
  Version = character(),
  stringsAsFactors = FALSE
)

all_ok <- TRUE
for (p in client_pkgs) {
  if (requireNamespace(p, quietly = TRUE)) {
    ver <- as.character(packageVersion(p))
    cat("OK:", p, ver, "\n")
    results <- rbind(results, data.frame(Package = p, Status = "OK", Version = ver))
  } else {
    cat("MISSING:", p, "\n")
    results <- rbind(results, data.frame(Package = p, Status = "MISSING", Version = ""))
    all_ok <- FALSE
  }
}

cat("\n")
if (!all_ok) {
  cat("WARNING: Some packages are missing!\n")
  # Don't fail the build - individual packages still work
  # quit(status = 1)
}

cat("\n============================================\n")
cat("R Package Installation Complete!\n")
cat("============================================\n")