#!/usr/bin/env Rscript
# ============================================
# R Package Installation Script
# Installs packages with caching-friendly output
# ============================================

# Configuration
install_repo <- "https://cloud.r-project.org"
lib_path <- "/usr/local/lib/R/site-library"
ncpus <- parallel::detectCores()

options(
  repos = c(CRAN = install_repo),
  warn = 1
)

# Read package list
packages_file <- "/tmp/r-packages.txt"
if (!file.exists(packages_file)) {
  stop("Package file not found: ", packages_file)
}

lines <- readLines(packages_file)
# Remove comments and empty lines
lines <- trimws(lines)
lines <- lines[!grepl("^#", lines)]
lines <- lines[lines != ""]

# Skip 'parallel' - it's a base R package
packages <- lines[lines != "parallel"]

cat("============================================\n")
cat("Installing", length(packages), "R packages\n")
cat("Using", ncpus, "CPU cores\n")
cat("============================================\n\n")

# Install each package
for (pkg in packages) {
  cat("\n>>> Installing:", pkg, "\n")
  
  tryCatch({
    if (!requireNamespace(pkg, quietly = TRUE)) {
      install.packages(
        pkg,
        lib = lib_path,
        repos = install_repo,
        dependencies = TRUE,
        Ncpus = ncpus
      )
    } else {
      cat("    Already installed, skipping\n")
    }
    
    # Verify installation
    if (requireNamespace(pkg, quietly = TRUE)) {
      ver <- as.character(packageVersion(pkg))
      cat("    SUCCESS:", pkg, ver, "\n")
    }
  }, error = function(e) {
    cat("    WARNING: Failed to install", pkg, "\n")
    cat("    Error:", conditionMessage(e), "\n")
  })
}

cat("\n============================================\n")
cat("Installation complete!\n")
cat("============================================\n")

# Print summary
installed <- installed.packages(lib.loc = lib_path)[, "Package"]
cat("\nInstalled packages:", length(installed), "\n")