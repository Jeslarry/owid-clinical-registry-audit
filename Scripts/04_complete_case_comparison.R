# ==============================================================================
# Script: 04_complete_case_comparison.R
# Purpose:
#   Evaluate data completeness in the cleaned OWID dataset.
#
#   PART A  : Country-level structural completeness
#   PART B  : Observation-level complete-case eligibility
#   PART C  : Baseline comparison of included vs excluded observations
#
# ==============================================================================

suppressPackageStartupMessages({
  library(tidyverse)
})

# ==============================================================================
# 1. LOAD DATA
# ==============================================================================

data_path <- "data/processed/owid_clean_countries.csv"

if (!file.exists(data_path)) {
  stop("Cannot find file:\n", data_path)
}

clean_countries <- read_csv(
  data_path,
  show_col_types = FALSE
)

cat("\nDataset loaded successfully.\n")
cat("Rows:", nrow(clean_countries), "\n")
cat("Columns:", ncol(clean_countries), "\n\n")

# ==============================================================================
# 2. DETERMINE COUNTRY IDENTIFIER
# ==============================================================================

if ("country" %in% names(clean_countries)) {
  
  country_var <- "country"
  
} else if ("location" %in% names(clean_countries)) {
  
  country_var <- "location"
  
} else {
  
  stop(
    "Neither 'country' nor 'location' exists in the dataset."
  )
  
}

cat("Country identifier:", country_var, "\n\n")

# ==============================================================================
# 3. CHECK REQUIRED VARIABLES
# ==============================================================================

required <- c(
  country_var,
  "total_deaths",
  "gdp_per_capita",
  "hospital_beds_per_thousand",
  "median_age"
)

missing_vars <- setdiff(required, names(clean_countries))

if (length(missing_vars) > 0) {
  
  stop(
    "Missing required variables:\n",
    paste(missing_vars, collapse = ", ")
  )
  
}

# ==============================================================================
# PART A
# COUNTRY-LEVEL STRUCTURAL COMPLETENESS
# ==============================================================================

country_profile <- clean_countries %>%
  group_by(.data[[country_var]]) %>%
  summarise(
    
    has_deaths = any(!is.na(total_deaths)),
    
    has_gdp = any(!is.na(gdp_per_capita)),
    
    has_beds = any(!is.na(hospital_beds_per_thousand)),
    
    has_age = any(!is.na(median_age)),
    
    .groups = "drop"
    
  ) %>%
  mutate(
    
    structurally_complete =
      has_deaths &
      has_gdp &
      has_beds &
      has_age
    
  )

complete_country_list <-
  country_profile %>%
  filter(structurally_complete) %>%
  pull(.data[[country_var]])

cat("====================================================\n")
cat("PART A : STRUCTURAL COMPLETENESS\n")
cat("====================================================\n")

cat("Countries evaluated: ",
    nrow(country_profile), "\n")

cat("Structurally complete countries: ",
    sum(country_profile$structurally_complete), "\n")

cat("Structurally incomplete countries: ",
    sum(!country_profile$structurally_complete), "\n\n")

# ==============================================================================
# PART B
# OBSERVATION-LEVEL ELIGIBILITY
# ==============================================================================

analytic_data <-
  clean_countries %>%
  mutate(
    
    structurally_complete =
      .data[[country_var]] %in%
      complete_country_list,
    
    complete_row =
      !is.na(total_deaths) &
      !is.na(gdp_per_capita) &
      !is.na(hospital_beds_per_thousand) &
      !is.na(median_age)
    
  )

cat("====================================================\n")
cat("PART B : OBSERVATION-LEVEL ELIGIBILITY\n")
cat("====================================================\n")

cat("Total observations: ",
    nrow(analytic_data), "\n")

cat("Rows with complete covariates: ",
    sum(analytic_data$complete_row), "\n")

cat("Rows with missing covariates: ",
    sum(!analytic_data$complete_row), "\n")

cat(sprintf(
  "Complete-case percentage: %.2f%%\n\n",
  mean(analytic_data$complete_row) * 100
))

# ==============================================================================
# PART C
# TABLE 1
# ==============================================================================

table1 <-
  analytic_data %>%
  mutate(
    
    inclusion_status =
      if_else(
        complete_row,
        "Included",
        "Excluded"
      )
    
  ) %>%
  group_by(inclusion_status) %>%
  summarise(
    
    observations = n(),
    
    countries =
      n_distinct(.data[[country_var]]),
    
    median_gdp =
      median(gdp_per_capita,
             na.rm = TRUE),
    
    median_beds =
      median(
        hospital_beds_per_thousand,
        na.rm = TRUE
      ),
    
    median_age =
      median(
        median_age,
        na.rm = TRUE
      ),
    
    .groups = "drop"
    
  )

cat("====================================================\n")
cat("TABLE 1\n")
cat("====================================================\n")

print(table1)

# ==============================================================================
# END
# ==============================================================================

cat("\nAnalysis completed successfully.\n")