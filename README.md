# A Reproducible Audit of Data Completeness in an International COVID-19 Registry

## Project Overview

This repository contains a reproducible data audit evaluating structural data completeness and observation-level complete-case eligibility within a global longitudinal health dataset. Using the public Our World in Data (OWID) COVID-19 dataset (543,069 observations across 239 countries and territories), this project demonstrates how standard complete-case filtering changes the composition of the final analytic sample before downstream statistical modelling.

### Key Finding

The audit shows that complete-case eligibility is associated with national economic resources and healthcare-system capacity. Consequently, complete-case filtering alters the composition of the analytic dataset and should be evaluated before interpreting epidemiological analyses or drawing public health conclusions.

---

# 1. Project Structure

This project is organised as a reproducible R workflow.

```text
owid-clinical-registry-audit/
├── README.md
├── data/
│   └── processed/
│       └── owid_clean_countries.csv
├── Scripts/
│   ├── 01_owid_ingestion_audit.R
│   ├── 02_real_data_profiling.R
│   ├── 03_cohort_filtration.R
│   └── 04_complete_case_comparison.R
└── Outputs/
```

---

# 2. Country-Level Structural Completeness

The first stage of the audit evaluated structural data availability at the country level.

A country was classified as **structurally complete** if it reported at least one non-missing value for each required baseline variable during the study period:

- Total deaths
- GDP per capita
- Hospital beds per thousand
- Median age

### Results

| Metric | Value |
|-------|------:|
| Countries evaluated | **239** |
| Structurally complete countries | **162** |
| Structurally incomplete countries | **77** |

This assessment measures long-term availability of essential variables and is distinct from observation-level complete-case eligibility.

---

# 3. Observation-Level Complete-Case Eligibility

Each country-day observation was then evaluated independently.

An observation was considered eligible only when all required variables were present on that specific row.

### Results

| Metric | Value |
|-------|------:|
| Total observations | **543,069** |
| Complete observations | **373,410** |
| Incomplete observations | **169,659** |
| Complete-case eligibility | **68.76%** |

These observations constitute the analytic dataset used for subsequent analyses.

---

# 4. Sample Composition Comparison

The complete-case filter changes the composition of the analytic dataset.

| Inclusion Status | Observations | Countries | Median GDP per Capita (USD) | Median Hospital Beds / 1,000 | Median Age |
|-----------------|------------:|----------:|----------------------------:|-----------------------------:|-----------:|
| Excluded | 169,659 | 229 | 10,281 | 2.21 | 35.2 |
| Included | 373,410 | 162 | 19,051 | 2.38 | 30.6 |

### Interpretation

Compared with excluded observations, the included analytic sample is associated with:

- substantially higher median GDP per capita;
- moderately higher hospital bed availability; and
- a younger median population age.

These descriptive differences indicate that complete-case eligibility is associated with underlying national characteristics rather than occurring randomly across the dataset.

---

# 5. Methodological Implications

This project distinguishes two related but different concepts:

1. **Country-Level Structural Completeness**
   - evaluates whether essential variables are available for a country at any point during the study period.

2. **Observation-Level Complete-Case Eligibility**
   - evaluates whether an individual country-day observation contains all variables required for analysis.

Separating these definitions improves transparency and prevents structural data availability from being confused with row-level analytic eligibility.

---

# 6. Public Health and Regulatory Relevance

This audit demonstrates that complete-case filtering can alter the characteristics of an international surveillance dataset before statistical modelling begins.

For epidemiological research, this highlights the importance of assessing completeness patterns before interpreting regression models or comparing countries.

For regulatory science and evidence evaluation, the project illustrates why analysts should understand how data-processing decisions influence the population represented by the final analytic dataset.

---

# Software

- R
- tidyverse
- readr
- dplyr
- ggplot2

---

# Reproducibility

The analyses are fully reproducible from the supplied R scripts and processed dataset. Running the project regenerates the reported descriptive summaries and completeness assessments.