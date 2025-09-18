# Datalab Week 3 — Read EAVS SPSS (zipped) from the web
# ------------------------------------------------------
# Requires: tidyverse, haven, janitor (optional)
# Installs if missing:
pkgs <- c("tidyverse", "haven", "janitor", "here")
to_install <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
if (length(to_install)) install.packages(to_install, dependencies = TRUE)

library(tidyverse)
library(haven)
library(janitor)
library(here)

# ---- 1) Source URL (zip containing .sav) ----
eavs_zip_url <- "https://www.eac.gov/sites/default/files/2025-06/2024_EAVS_for_Public_Release_V1.sav_.zip"

# ---- 2) Temp paths ----
tdir <- tempfile("eavs_zip_")
dir.create(tdir, showWarnings = FALSE)
zip_path <- file.path(tdir, "eavs_2024.zip")

# ---- 3) Download the zip ----
# Use mode = "wb" to avoid corruption on Windows
download.file(eavs_zip_url, destfile = zip_path, mode = "wb", quiet = FALSE)

# ---- 4) Unzip and locate the .sav ----
unzipped <- unzip(zip_path, exdir = tdir)
sav_files <- unzipped[grepl("\\.sav$", unzipped, ignore.case = TRUE)]
if (length(sav_files) == 0) stop("No .sav file found inside the downloaded zip.")
sav_path <- sav_files[1]  # assume the first .sav is the main file

message("Found SPSS file: ", basename(sav_path))

# ---- 5) Read SPSS with labels preserved ----
# user_na=TRUE keeps SPSS user-missing codes distinct from NA (see haven docs)
eavs_raw <- read_sav(sav_path, user_na = TRUE)

# ---- 6) Clean column names; keep labels for reference ----
# You’ll get clean snake_case names but retain the SPSS labels as attributes.
eavs <- eavs_raw %>%
  as_tibble() %>%
  janitor::clean_names()

# (Optional) A named vector of variable labels you can use in tables/plots
var_labels <- sapply(eavs_raw, function(x) attr(x, "label"))
names(var_labels) <- names(eavs)  # align labels to cleaned names

# (Optional) Convert labelled values to factors for analysis/plots.
# Comment this out if you prefer to keep them as labelled.
eavs_factor <- eavs %>%
  mutate(across(where(is.labelled), haven::as_factor, levels = "labels"))

# ---- 7) Quick sanity checks ----
message("Rows x Cols (labelled): ", paste(dim(eavs), collapse = " x "))
print(head(eavs, 3))

# ---- 8) Save a cached copy for faster reloads later ----
#saveRDS(eavs, file = "eavs_2024_labelled_clean_names.rds")
#saveRDS(eavs_factor, file = "eavs_2024_factors_clean_names.rds")

# Tip:
#   - Use `eavs` when you want to retain numeric codes + labels.
#   - Use `eavs_factor` when you want factor levels with human-readable labels.
#   - `var_labels` gives you the original SPSS variable descriptions.
