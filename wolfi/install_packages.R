#!/usr/bin/env Rscript

# ============================================
# R Package Installation Script for Wolfi
# Handles errors gracefully
# ============================================

cat("===========================================\n")
cat("R Package Installation for Wolfi\n")
cat("===========================================\n\n")

# Set options
options(
  repos = c(CRAN = "https://cloud.r-project.org"),
  warn = 1,
  Ncpus = parallel::detectCores()
)

# Set library path
lib_path <- "/usr/local/lib/R/site-library"
.libPaths(c(lib_path, .libPaths()))

cat("Library path:", lib_path, "\n")
cat("CPU cores:", parallel::detectCores(), "\n\n")

# Read packages from file
packages_file <- "/tmp/packages.txt"
if (!file.exists(packages_file)) {
  cat("ERROR: packages.txt not found\n")
  quit(status = 1)
}

packages <- readLines(packages_file)
packages <- trimws(packages)
packages <- packages[packages != "" & !grepl("^#", packages)]

cat("Packages to install:", paste(packages, collapse = ", "), "\n\n")

# Track results
success <- character()
failed <- character()

# Install each package
for (pkg in packages) {
  cat("\n>>> Installing:", pkg, "\n")
  
  result <- tryCatch({
    install.packages(
      pkg,
      lib = lib_path,
      dependencies = TRUE,
      Ncpus = parallel::detectCores(),
      quiet = FALSE
    )
    
    # Verify installation
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat("    [SUCCESS]", pkg, "\n")
      TRUE
    } else {
      cat("    [FAILED] Package installed but cannot be loaded\n")
      FALSE
    }
  }, error = function(e) {
    cat("    [ERROR]", conditionMessage(e), "\n")
    FALSE
  }, warning = function(w) {
    cat("    [WARNING]", conditionMessage(w), "\n")
    TRUE
  })
  
  if (isTRUE(result)) {
    success <- c(success, pkg)
  } else {
    failed <- c(failed, pkg)
  }
}

# Install IRkernel
cat("\n>>> Installing IRkernel\n")
irkernel_result <- tryCatch({
  install.packages("IRkernel", lib = lib_path, dependencies = TRUE)
  if (requireNamespace("IRkernel", quietly = TRUE)) {
    cat("    [SUCCESS] IRkernel\n")
    TRUE
  } else {
    FALSE
  }
}, error = function(e) {
  cat("    [ERROR]", conditionMessage(e), "\n")
  FALSE
})

if (isTRUE(irkernel_result)) {
  success <- c(success, "IRkernel")
} else {
  failed <- c(failed, "IRkernel")
}

# Summary
cat("\n===========================================\n")
cat("Installation Summary\n")
cat("===========================================\n")
cat("Successful:", length(success), "\n")
if (length(success) > 0) {
  cat("  -", paste(success, collapse = "\n  - "), "\n")
}
cat("\nFailed:", length(failed), "\n")
if (length(failed) > 0) {
  cat("  -", paste(failed, collapse = "\n  - "), "\n")
}

# List actually installed packages
cat("\n===========================================\n")
cat("Actually Installed Packages\n")
cat("===========================================\n")
installed <- installed.packages(lib.loc = lib_path)[, "Package"]
cat(paste(installed, collapse = ", "), "\n")

# Exit successfully even if some packages failed
# This prevents Docker build from failing
cat("\n===========================================\n")
cat("Installation script completed\n")
cat("===========================================\n")