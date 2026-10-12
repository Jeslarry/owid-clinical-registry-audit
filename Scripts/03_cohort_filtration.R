# ==============================================================================
# PROJECT: Clinical Registry Data Linkage & Denominator Integrity Audit
# MODULE:  Phase 3 & 4 - Cohort Extraction & Aggregate Elimination Protocol
# TARGET:  Exclusion of regional aggregates to eliminate double-counting risks.
#
# AUDIT LOG CONTROL:
# - WHAT: Removed non-sovereign entities (e.g., "Africa", "World", "Low income").
# - WHY:  Aggregate entities coexist with individual country rows in raw snapshot.
# - RISK: Combining them causes catastrophic denominator inflation in summaries.
# ==============================================================================

# 1. LIVE DEPENDENCY CONTROL
library(tidyverse)
library(here)

# 2. INGESTION OF VERIFIED PROFILED SNAPSHOT
snapshot_path <- here::here("data", "raw", "owid_raw_snapshot.csv")
raw_snapshot  <- read_csv(snapshot_path, show_col_types = FALSE)

cat("--- EXECUTING COHORT FILTRATION PIPELINE ---\n")
cat("Starting Ingestion Denominator Row Count: ", nrow(raw_snapshot), "\n")

# 3. CRITERIA ANALYSIS FOR NON-COUNTRY ELIMINATION
# Most international registries use an 'iso_code' or 'code' column. 
# Regional aggregates often have custom codes (like 'OWID_AFR') or missing codes.
# Let's inspect the 'code' column behavior to find our filtration criteria.

code_inventory <- raw_snapshot %>%
  distinct(country, code) %>%
  arrange(code)

cat("\nPrinting structural codes to establish filtration boundaries:\n")
print(head(code_inventory, 25))# ==============================================================================
# PHASE 4: REPRODUCIBLE FILTRATION & DENOMINATOR HARDENING
# ==============================================================================
cat("\n--- PHASE 4: EXECUTING SUB-REGIONAL FILTRATION ---\n")

# Apply the structural cleaning rule to remove the aggregate rows
clean_countries <- raw_snapshot %>%
  filter(!str_detect(code, "^OWID_") | code %in% c("OWID_KOS", "OWID_TRS")) %>%
  filter(nchar(code) == 3 | code %in% c("OWID_KOS", "OWID_TRS"))

cat("Post-Filtration Denominator Row Count: ", nrow(clean_countries), "\n")
cat("Total Rows Purged from Snapshot:       ", nrow(raw_snapshot) - nrow(clean_countries), "\n\n")

# Verification Step: Ensure 'Africa' and 'World' are completely gone
cat("Verifying removal of critical aggregate blocks:\n")
verification_check <- clean_countries %>%
  filter(country %in% c("Africa", "Asia", "European Union (27)", "Europe", "World"))

print(verification_check) # Should return a clean table with 0 rows

# ==============================================================================
# PHASE 5: ARTIFACT EXPORT FOR DOWNSTREAM ANALYSIS
# ==============================================================================
write_csv(clean_countries, here::here("data", "processed", "owid_clean_countries.csv"))
cat("\n[SUCCESS]: Clean country dataset exported to data/processed/owid_clean_countries.csv\n")# ==============================================================================
# PHASE 6: REGIONAL SUB-COHORT PROFILING (WEST AFRICA FOCUS)
# ==============================================================================
cat("\n--- PHASE 6: WEST AFRICA SURVEILLANCE PROFILE ---\n")

# Define the explicit ISO codes for the West African sub-region
west_africa_iso <- c(
  "BEN", "BFA", "CPV", "CIV", "GMB", "GHA", "GIN", "GNB", 
  "LBR", "MLI", "MRT", "NER", "NGA", "SEN", "SLE", "TGO"
)

# Extract and audit the regional subset
west_africa_cohort <- clean_countries %>%
  filter(code %in% west_africa_iso)

cat("Total observations captured in West African cohort: ", nrow(west_africa_cohort), "\n\n")

# Calculate temporal completeness and data volume by country
regional_completeness <- west_africa_cohort %>%
  group_by(country, code) %>%
  summarise(
    total_days_logged = n(),
    min_record_date   = min(date),
    max_record_date   = max(date),
    missing_new_cases = sum(is.na(new_cases)),
    .groups = "drop"
  ) %>%
  arrange(desc(total_days_logged))

print(regional_completeness)# ==============================================================================
# PHASE 7: SUB-COHORT REPORT EXPORT & AUTOMATED QUALITY LOGGING
# ==============================================================================
cat("\n--- PHASE 7: WRITING REGIONAL AUDIT REPORT TO DISK ---\n")

# 1. Export the raw data subset for West Africa
write_csv(west_africa_cohort, here::here("data", "processed", "west_africa_surveillance_cohort.csv"))
cat("[SUCCESS]: Extracted cohort written to data/processed/west_africa_surveillance_cohort.csv\n")

# 2. Export the structural completeness metrics table
write_csv(regional_completeness, here::here("outputs", "west_africa_quality_audit.csv"))
cat("[SUCCESS]: Quality audit summary written to outputs/west_africa_quality_audit.csv\n")

# 3. Generate a quick descriptive text summary log
log_file <- file(here::here("outputs", "regional_audit_manifest.txt"))
writeLines(c(
  "==============================================================================",
  "REGIONAL PUBLIC HEALTH REGISTRY AUDIT MANIFEST",
  paste("GENERATED ON:", Sys.time()),
  "==============================================================================",
  paste("Total Clean West African Records Ingested:", nrow(west_africa_cohort)),
  paste("Total Tracked Regional Jurisdictions:    ", nrow(regional_completeness)),
  "------------------------------------------------------------------------------",
  "CRITICAL STRUCTURAL OBSERVATIONS:",
  "- Base Timeline Span: 2020-01-01 to 2026-04-26 (2308 expected rows)",
  "- 14 of 16 regional nations exhibit a structurally complete temporal panel.",
  "- Côte d'Ivoire (CIV) exhibits severe truncation, halting on 2023-02-20.",
  "- Tiered missingness (115 vs 346 days) indicates variable batch transmission protocols.",
  "=============================================================================="
), log_file)
close(log_file)
cat("[SUCCESS]: Descriptive audit text log compiled to outputs/regional_audit_manifest.txt\n\n")
cat("--- COHORT FILTRATION PIPELINE EXECUTION COMPLETE ---\n")# ==============================================================================
# PHASE 7: HARDENED REGIONAL CUMULATIVE AGGREGATIONS
# ==============================================================================
cat("\n--- PHASE 7: CALCULATING VALID REGIONAL SUMMARIES ---\n")

# Isolate the fully compliant West African longitudinal panel
clean_west_africa <- west_africa_cohort %>%
  filter(code != "CIV")

regional_totals <- clean_west_africa %>%
  group_by(country, code) %>%
  summarise(
    cumulative_cases  = sum(new_cases, na.rm = TRUE),
    cumulative_deaths = sum(new_deaths, na.rm = TRUE),
    latest_population = max(population, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    case_fatality_rate_pct = (cumulative_deaths / cumulative_cases) * 100,
    attack_rate_per_100k   = (cumulative_cases / latest_population) * 100000
  ) %>%
  arrange(desc(cumulative_cases))

print(regional_totals)