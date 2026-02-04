#!/usr/bin/env Rscript
# ============================================
# R Package Installation Script
# Reads from: /tmp/packages/r-packages.txt
# R Version: 4.1.0
# ============================================

lib_path <- "/usr/local/lib/R/site-library"
pkg_file <- "/tmp/packages/r-packages.txt"
ncpus <- parallel::detectCores()

options(
  repos = c(CRAN = "https://cloud.r-project.org"),
  warn = 1,
  Ncpus = ncpus,
  timeout = 300
)

cat("============================================\n")
cat("R Package Installation\n")
cat("============================================\n")
cat("R Version:", as.character(getRversion()), "\n")
cat("Library:", lib_path, "\n")
cat("CPUs:", ncpus, "\n")
cat("Package File:", pkg_file, "\n")
cat("============================================\n\n")

# Ensure library path exists
if (!dir.exists(lib_path)) {
  dir.create(lib_path, recursive = TRUE)
}
.libPaths(lib_path)

# ============================================
# Define Base R Packages (skip these)
# ============================================
base_r_packages <- c(
  "base", "compiler", "datasets", "graphics", "grDevices", "grid",
  "methods", "parallel", "splines", "stats", "stats4", "tcltk",
  "tools", "translations", "utils",
  "boot", "class", "cluster", "codetools", "foreign", "KernSmooth",
  "lattice", "MASS", "Matrix", "mgcv", "nlme", "nnet", "rpart",
  "spatial", "survival"
)

# ============================================
# Define Archived Packages
# ============================================
archived_packages <- list(
  "tibbletime" = "https://cran.r-project.org/src/contrib/Archive/tibbletime/tibbletime_0.1.8.tar.gz",
  "sweep" = "https://cran.r-project.org/src/contrib/Archive/sweep/sweep_0.2.5.tar.gz"
)

# ============================================
# Read and Parse r-packages.txt
# ============================================
cat("=== Reading Package List ===\n")

if (!file.exists(pkg_file)) {
  stop("ERROR: Package file not found: ", pkg_file)
}

lines <- readLines(pkg_file, warn = FALSE)
lines <- trimws(lines)
lines <- lines[lines != "" & !grepl("^#", lines)]

packages <- data.frame(
  name = character(),
  version = character(),
  stringsAsFactors = FALSE
)

for (line in lines) {
  if (grepl("==", line)) {
    parts <- strsplit(line, "==")[[1]]
    pkg_name <- trimws(parts[1])
    pkg_version <- trimws(parts[2])
  } else {
    pkg_name <- trimws(line)
    pkg_version <- ""
  }
  
  # Skip base R packages
  if (!pkg_name %in% base_r_packages) {
    packages <- rbind(packages, data.frame(
      name = pkg_name,
      version = pkg_version,
      stringsAsFactors = FALSE
    ))
  }
}

cat("Found", nrow(packages), "packages to install\n\n")

# ============================================
# Installation Function
# ============================================
install_pkg <- function(pkg, version = NULL, retries = 3) {
  # Check if already installed
  if (requireNamespace(pkg, quietly = TRUE)) {
    installed_ver <- as.character(packageVersion(pkg))
    if (is.null(version) || version == "" || installed_ver == version) {
      cat("  SKIP:", pkg, installed_ver, "(already installed)\n")
      return(TRUE)
    }
  }
  
  cat(">>> Installing:", pkg)
  if (!is.null(version) && version != "") {
    cat(" (version", version, ")")
  }
  cat("\n")
  
  for (attempt in 1:retries) {
    result <- tryCatch({
      # Check if archived package
      if (pkg %in% names(archived_packages)) {
        cat("    Installing from archive...\n")
        install.packages(
          archived_packages[[pkg]],
          repos = NULL,
          type = "source",
          lib = lib_path,
          Ncpus = ncpus
        )
      } else if (!is.null(version) && version != "") {
        # Install specific version
        if (!requireNamespace("remotes", quietly = TRUE)) {
          install.packages("remotes", lib = lib_path, quiet = TRUE)
        }
        remotes::install_version(
          pkg,
          version = version,
          lib = lib_path,
          upgrade = "never",
          quiet = FALSE,
          dependencies = TRUE,
          Ncpus = ncpus
        )
      } else {
        # Install latest version
        install.packages(
          pkg,
          lib = lib_path,
          dependencies = TRUE,
          Ncpus = ncpus
        )
      }
      
      if (requireNamespace(pkg, quietly = TRUE)) {
        cat("    OK:", pkg, as.character(packageVersion(pkg)), "\n")
        return(TRUE)
      }
      return(FALSE)
    }, error = function(e) {
      cat("    Attempt", attempt, "failed:", conditionMessage(e), "\n")
      if (attempt < retries) Sys.sleep(2)
      return(FALSE)
    })
    
    if (result) return(TRUE)
  }
  
  # Fallback: try latest if specific version failed
  if (!is.null(version) && version != "") {
    cat("    Trying latest version as fallback...\n")
    tryCatch({
      install.packages(pkg, lib = lib_path, dependencies = TRUE, Ncpus = ncpus)
      if (requireNamespace(pkg, quietly = TRUE)) {
        cat("    OK (fallback):", pkg, as.character(packageVersion(pkg)), "\n")
        return(TRUE)
      }
    }, error = function(e) {
      cat("    Fallback failed\n")
    })
  }
  
  cat("    FAILED:", pkg, "\n")
  return(FALSE)
}

# ============================================
# Priority Installation Order
# ============================================
priority_order <- c(
  "remotes",
  "rlang", "cli", "glue", "lifecycle", "vctrs", "pillar",
  "R6", "Rcpp", "magrittr", "ellipsis", "fansi", "utf8",
  "pkgconfig", "digest", "crayon", "withr", "ps", "processx", "callr",
  "BH", "cpp11", "RcppArmadillo", "RcppRoll",
  "sys", "askpass", "openssl", "curl", "jsonlite", "mime", "httr",
  "stringi", "stringr",
  "tibble", "tidyselect", "dplyr", "tidyr", "purrr", "generics", "broom",
  "bit", "bit64", "blob", "DBI", "vroom", "readr", "readxl", "haven",
  "data.table", "dtplyr", "cellranger", "dbplyr",
  "lubridate", "hms", "tzdb", "anytime", "timeDate",
  "colorspace", "farver", "labeling", "munsell", "RColorBrewer",
  "viridisLite", "scales", "isoband", "gtable", "ggplot2",
  "base64enc", "htmltools", "jquerylib", "sass", "bslib",
  "htmlwidgets", "crosstalk", "plotly", "later", "promises",
  "yaml", "xfun", "highr", "evaluate", "knitr", "rmarkdown", "tinytex",
  "globals", "listenv", "parallelly", "future", "future.apply", "furrr",
  "foreach", "iterators", "doParallel", "pbapply", "progressr",
  "quadprog", "numDeriv", "SQUAREM", "lmtest", "lava", "prodlim",
  "ipred", "gower", "hardhat", "recipes", "rsample",
  "zoo", "xts", "TTR", "quantmod", "fracdiff", "forecast", "urca", "tseries", "tsfeatures",
  "forcats", "modelr", "reprex", "rvest", "selectr", "xml2",
  "gargle", "googledrive", "googlesheets4",
  "assertthat", "backports", "cachem", "fastmap", "memoise", "rappdirs",
  "clipr", "fs", "lazyeval", "rematch", "rematch2", "ids", "uuid",
  "plyr",
  "warp", "slider", "padr", "timetk",
  "tibbletime", "sweep",
  "anomalize",
  "tidyverse",
  "rstudioapi",
  "repr", "IRdisplay", "pbdZMQ",
  "IRkernel"
)

# ============================================
# Phase 1: Install remotes
# ============================================
cat("\n=== Phase 1: Installing remotes ===\n")
install.packages("remotes", lib = lib_path, quiet = TRUE)

# ============================================
# Phase 2: Install in Priority Order
# ============================================
cat("\n=== Phase 2: Installing Packages ===\n")

installed_ok <- character()
installed_fail <- character()

# Install priority packages first
for (pkg in priority_order) {
  idx <- which(packages$name == pkg)
  if (length(idx) > 0) {
    version <- packages$version[idx[1]]
    if (install_pkg(pkg, if(version == "") NULL else version)) {
      installed_ok <- c(installed_ok, pkg)
    } else {
      installed_fail <- c(installed_fail, pkg)
    }
  }
}

# Install remaining packages
remaining <- packages$name[!packages$name %in% c(installed_ok, installed_fail)]
cat("\n=== Phase 3: Installing Remaining (", length(remaining), ") ===\n")

for (pkg in remaining) {
  idx <- which(packages$name == pkg)
  version <- packages$version[idx[1]]
  if (install_pkg(pkg, if(version == "") NULL else version)) {
    installed_ok <- c(installed_ok, pkg)
  } else {
    installed_fail <- c(installed_fail, pkg)
  }
}

# ============================================
# Phase 4: Special pbdZMQ Installation
# ============================================
if ("pbdZMQ" %in% packages$name && !"pbdZMQ" %in% installed_ok) {
  cat("\n=== Phase 4: Special pbdZMQ ===\n")
  tryCatch({
    Sys.setenv(ZMQ_INCLUDE = "/usr/include", ZMQ_LIB = "/usr/lib")
    install.packages("pbdZMQ", lib = lib_path,
      configure.args = "--with-zmq-include=/usr/include --with-zmq-lib=/usr/lib",
      Ncpus = ncpus)
    if (requireNamespace("pbdZMQ", quietly = TRUE)) {
      cat("    OK: pbdZMQ\n")
      installed_ok <- c(installed_ok, "pbdZMQ")
      installed_fail <- installed_fail[installed_fail != "pbdZMQ"]
    }
  }, error = function(e) {
    cat("    pbdZMQ failed:", conditionMessage(e), "\n")
  })
}

# ============================================
# Verification
# ============================================
cat("\n============================================\n")
cat("VERIFICATION\n")
cat("============================================\n\n")

# Verify all packages
all_ok <- 0
all_fail <- 0

for (i in 1:nrow(packages)) {
  pkg <- packages$name[i]
  req_ver <- packages$version[i]
  
  if (requireNamespace(pkg, quietly = TRUE)) {
    inst_ver <- as.character(packageVersion(pkg))
    cat("  OK:", pkg, inst_ver)
    if (req_ver != "" && inst_ver != req_ver) {
      cat(" (requested:", req_ver, ")")
    }
    cat("\n")
    all_ok <- all_ok + 1
  } else {
    cat("  MISSING:", pkg, "\n")
    all_fail <- all_fail + 1
  }
}

# ============================================
# Key Package Verification
# ============================================
cat("\n=== Key Packages ===\n")
key_pkgs <- c("rstudioapi", "dplyr", "ggplot2", "tidyverse", "forecast", 
              "anomalize", "tibbletime", "timetk", "IRkernel")

for (pkg in key_pkgs) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat("  OK:", pkg, as.character(packageVersion(pkg)), "\n")
  } else {
    cat("  MISSING:", pkg, "\n")
  }
}

# Verify rstudioapi version specifically
cat("\n=== rstudioapi Verification ===\n")
if (requireNamespace("rstudioapi", quietly = TRUE)) {
  ver <- as.character(packageVersion("rstudioapi"))
  cat("  rstudioapi version:", ver, "\n")
  if (ver == "0.14") {
    cat("  STATUS: OK - Matches requested version 0.14\n")
  } else {
    cat("  STATUS: WARNING - Requested 0.14, got", ver, "\n")
  }
} else {
  cat("  STATUS: ERROR - rstudioapi not installed!\n")
}

# ============================================
# Summary
# ============================================
cat("\n============================================\n")
cat("SUMMARY\n")
cat("============================================\n")
cat("Total requested:", nrow(packages), "\n")
cat("Installed:", all_ok, "\n")
cat("Failed:", all_fail, "\n")
cat("Success rate:", round(all_ok/nrow(packages) * 100, 1), "%\n")

if (all_fail > 0) {
  cat("\nFailed packages:\n")
  for (pkg in installed_fail) {
    cat("  -", pkg, "\n")
  }
}

cat("\n============================================\n")
cat("R Package Installation Complete!\n")
cat("R Version:", as.character(getRversion()), "\n")
cat("============================================\n")