# Data Lab Week 3 — Read EAVS 2024 SPSS (zipped) from the web
# -----------------------------------------------------------
# Requires: tidyverse, haven, janitor
pkgs <- c("tidyverse", "haven", "janitor")
to_install <- pkgs[!pkgs %in% installed.packages()[, "Package"]]
if (length(to_install)) install.packages(to_install)

library(tidyverse)
library(haven)
library(janitor)

# 1) URL
eavs_zip_url <- "https://www.eac.gov/sites/default/files/2025-06/2024_EAVS_for_Public_Release_V1.sav_.zip"

# 2) Temp locations
zip_path <- tempfile(fileext = ".zip")
exdir    <- file.path(tempdir(), "eavs_2024")
dir.create(exdir, showWarnings = FALSE)

# 3) Download
download.file(eavs_zip_url, destfile = zip_path, mode = "wb")

# 4) Unzip (zip creates a subfolder named "... .sav" containing the .sav file)
unzip(zip_path, exdir = exdir)

# 5) Known, hard-coded path to the .sav (folder + file share the same name)
sav_path <- file.path(
  exdir,
  "2024_EAVS_for_Public_Release_V1.sav",
  "2024_EAVS_for_Public_Release_V1.sav"
)

# 6) Read SPSS with labels preserved
eavs_raw <- read_sav(sav_path, user_na = TRUE)

# Handle missing values. Code adapted from ENP Assignment

missing_codes_num  <- c(-77, -88, -99)
missing_codes_char <- as.character(missing_codes_num)

eavs_raw <- eavs_raw %>%
  # numeric columns
  mutate(across(
    where(is.numeric),
    ~ ifelse(. %in% missing_codes_num, NA, .)
  )) %>%
  # character columns
  mutate(across(
    where(is.character),
    ~ ifelse(. %in% missing_codes_char, NA, .)
  )) %>%
  # factor columns
  mutate(across(
    where(is.factor),
    ~ {
      x <- as.character(.)
      x[x %in% missing_codes_char] <- NA_character_
      factor(x)
    }
  ))


# 7) Clean names (simple, class-friendly)
eavs <- eavs_raw %>%
  as_tibble() %>%
  clean_names()

# Quick sanity checks
dim(eavs)
head(eavs, 3)
