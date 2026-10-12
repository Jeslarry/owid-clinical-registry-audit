# ------------------------------------------------------------------------------
# DRILL 5E: DE-DUPLICATION FOR DISTINCT DEMOGRAPHIC SUMMARIES
# ------------------------------------------------------------------------------
cat("\n--- FINAL DEMOGRAPHIC RECONCILIATION ---\n")

# Isolate unique human individuals within our active prescription pool
distinct_med_patients <- active_med_cohort %>%
  distinct(patient_id, .keep_all = TRUE)

cat("True unique human individuals on medication: ", nrow(distinct_med_patients), "\n")
print(distinct_med_patients)

# Recalculate true mean age based on distinct participants
true_mean_age <- mean(distinct_med_patients$age)
cat("\nTrue corrected mean age of medicated cohort: ", true_mean_age, " years\n")