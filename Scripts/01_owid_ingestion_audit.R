library(tidyverse)
library(here)

# 1. Ingest Data (Reading from your frozen processed csv source)
raw_data_path <- here("data", "processed", "owid_clean_countries.csv")

if (!file.exists(raw_data_path)) {
  stop("CRITICAL DATA HOLE: 'owid_clean_countries.csv' not found in data/processed/. Did you delete the data file?")
}

raw_data <- read_csv(raw_data_path, show_col_types = FALSE)

# 2. Variable Missingness Check (ALCOA+ Ingestion Audit Layer)
cat("=== VARIABLE MISSINGNESS CHECK ===\n")
print(colSums(is.na(raw_data %>% select(total_deaths_per_million, gdp_per_capita, hospital_beds_per_thousand, median_age, human_development_index))))
cat("\n")

# 3. Aggregate to Cross-Sectional Country Units
country_data <- raw_data %>%
  group_by(country) %>%
  summarise(
    total_deaths_per_million   = max(total_deaths_per_million, na.rm = TRUE),
    gdp_per_capita             = first(gdp_per_capita),
    hospital_beds_per_thousand = first(hospital_beds_per_thousand),
    median_age                 = first(median_age),
    .groups = "drop"
  ) %>%
  # Complete-case restriction rule (Programmatic filtering over manual selection)
  filter(
    !is.na(total_deaths_per_million), !is.inf(total_deaths_per_million),
    !is.na(gdp_per_capita),
    !is.na(hospital_beds_per_thousand),
    !is.na(median_age)
  )

cat(sprintf("=== ANALYTIC SAMPLE CREATED: %d Countries ===\n\n", nrow(country_data)))

# 4. Compute Base Medians for Portfolio Evaluation
table1_medians <- country_data %>%
  summarise(
    n_countries = n(),
    median_gdp  = median(gdp_per_capita),
    median_beds = median(hospital_beds_per_thousand),
    median_age  = median(median_age)
  )

print(as.data.frame(table1_medians))
write_csv(country_data, here("data", "processed", "analytic_cohort.csv"))