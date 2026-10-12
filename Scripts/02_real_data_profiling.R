# ==============================================================================
# PROJECT: Clinical Registry Data Linkage & Denominator Integrity Audit
# MODULE:  Phase 1 & 2 - Automated Profiling of OWID Snapshot Data
# GOAL:    Ingest a 166MB data matrix via relative pathways, map types,
#          and extract a prioritized missingness report to outputs/.
# ==============================================================================

# 1. LIVE DEPENDENCY CONTROL
if (!require("tidyverse")) install.packages("tidyverse", quiet = TRUE)
if (!require("here")) install.packages("here", quiet = TRUE)

library(tidyverse)
library(here)

cat("--- EXECUTING EXTERNAL SNAPSHOT SCHEMA PROFILING ---\n\n")

# 2. ANCHORED PERSISTENT PATH INGESTION
# Safely maps directly to your large file through the sub-folder structure
snapshot_path <- here::here("data", "raw", "owid_raw_snapshot.csv")

# Optimized block parsing to protect local memory
raw_snapshot <- read_csv(snapshot_path, show_col_types = FALSE)

# 3. PHASE 1: COMPUTE STRUCTURAL METRICS
cat("--- PHASE 1: DATABASE DIMENSIONS ---\n")
cat("Total Observations (Rows):    ", nrow(raw_snapshot), "\n")
cat("Total Captured Variables (Cols):", ncol(raw_snapshot), "\n\n")

# 4. PHASE 2: AUTOMATED VECTORIZED MISSINGNESS PROFILE
cat("--- PHASE 2: CALCULATING MISSINGNESS FREQUENCIES... ---\n")

missingness_analysis <- raw_snapshot %>%
  summarise(
    across(
      everything(),
      list(
        total_na = ~ sum(is.na(.)),
        percent_na   = ~ mean(is.na(.)) * 100
      )
    )
  ) %>%
  pivot_longer(
    cols = everything(),
    names_to = c("variable_name", ".value"),
    names_pattern = "(.*)_(total_na|percent_na)"
  ) %>%
  arrange(desc(percent_na)) # Immediately highlights the worst data gaps

# Display the top 12 variables missing the most data points
print(head(missingness_analysis, 12))

# 5. REPRODUCIBLE DIRECTORY ARTIFACT EXPORT
write_csv(missingness_analysis, here::here("outputs", "real_missingness_report.csv"))
cat("\n[SUCCESS]: Structured analysis log written to outputs/real_missingness_report.csv\n")
cat("--- SYSTEM PROFILING COMPLETE ---\n")# ==============================================================================
# PHASE 3: CATEGORICAL TYPE VERIFICATION & SCHEMA INTEGRITY
# ==============================================================================
cat("\n--- PHASE 3: CATEGORICAL FIELD AUDIT ---\n")

# 1. Audit the geographical tracking variable
# Since your columns printed successfully, let's target 'location'
unique_geographies <- raw_snapshot %>% 
  distinct(country) %>% 
  arrange(country)

cat("Total unique geographical entities tracked: ", nrow(unique_geographies), "\n\n")

# Print the top 20 rows to visually inspect for text fragmentation
cat("First 20 geographical entities in alphabetized index:\n")
print(head(unique_geographies, 20))

# 2. Audit the data timeline tracking structure
cat("\nChecking date format consistency:\n")
date_profile <- raw_snapshot %>%
  summarise(
    min_date = min(date, na.rm = TRUE),
    max_date = max(date, na.rm = TRUE),
    date_type = class(date)
  )
print(date_profile)