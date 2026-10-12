library(dplyr)

# ------------------------------------------------------------------------------
# INGESTION LAYER
# ------------------------------------------------------------------------------
# BUG 1: Ingestion reference error
raw_df <- dplyr::storms

print(dim(raw_df))

# ------------------------------------------------------------------------------
# CLEANING & TRANSFORMATION LAYER
# ------------------------------------------------------------------------------
# BUG 2: Non-existent column name inside select()
# BUG 3: Typo in the mutate function call
processed_df <- raw_df %>%
  filter(year >= 2000) %>%
  select(name, year, month, status, wind, pressure) %>%
  rename(storm_name = name, storm_status = status) %>%
  mutate(
    year = as.integer(year),
    wind = as.numeric(wind)
  )

# ------------------------------------------------------------------------------
# AGGREGATION LAYER
# ------------------------------------------------------------------------------
# BUG 4: Grouping variable error
# BUG 5: Missing missing-value argument
storm_metrics <- processed_df %>%
  group_by(storm_status) %>%
  summarise(
    total_observations  = n(),
    mean_wind_speed     = mean(wind,na.im = TRUE),
    .groups = "drop"
  )

# ------------------------------------------------------------------------------
# VERIFICATION OUTPUT
# ------------------------------------------------------------------------------
print(storm_metrics)