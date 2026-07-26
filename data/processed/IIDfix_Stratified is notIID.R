library(tidyverse)

# answer of the universe
set.seed(42)
TARGET_N <- 1000
EXPLORE_FRAC <- 0.30

# data man
# (subgroup == "all", gap == FALSE, year 2018).
pop <- read_csv("data/processed/seda_population_2018.csv", show_col_types = FALSE)


id_vars <- c("sedalea", "sedaleaname", "stateabb", "fips")
outcome <- "cs_mn_avg_ol"
outcome_se <- "cs_mn_avg_ol_se"
ses_comp <- c(
  "baplusall",
  "povertyall",
  "unempall",
  "snapall",
  "single_momall",
  "lninc50all"
)
enrollment <- "totenrl"
race <- c("perwht", "perblk", "perhsp", "perasn", "pernam")

analysis_vars <- c(outcome, ses_comp, enrollment, race)

frame <- pop %>%
  select(all_of(c(id_vars, outcome_se, analysis_vars)))


n_start <- nrow(frame)

frame_clean <- frame %>%
  filter(totenrl > 0) %>%
  drop_na(all_of(analysis_vars))

n_dropped <- n_start - nrow(frame_clean)
cat(sprintf(
  "Frame: %d districts -> %d after cleaning (dropped %d, %.1f%%)\n",
  n_start, nrow(frame_clean), n_dropped, 100 * n_dropped / n_start
))

# validate its IID
stopifnot(TARGET_N <= nrow(frame_clean))

sample_df <- frame_clean %>%
  slice_sample(n = TARGET_N) %>%
  mutate(split = if_else(row_number() <= floor(EXPLORE_FRAC * TARGET_N),
    "exploration", "confirmation"
  ))

# fix the gitignore
write_csv(sample_df, "data/processed/seda_2018_srs.csv")
write_csv(filter(sample_df, split == "exploration"), "data/processed/seda_2018_exploration.csv")
write_csv(filter(sample_df, split == "confirmation"), "data/processed/seda_2018_confirmation.csv")




run_checks <- function(df) {
  results <- c()

  stopifnot(nrow(df) == TARGET_N)
  results <- c(results, sprintf("PASS  Test 1: sample has %d rows", nrow(df)))

  stopifnot(!any(is.na(df %>% select(all_of(analysis_vars)))))
  results <- c(results, "PASS  Test 2: no NAs in the analysis variables")

  stopifnot(all(df$totenrl > 0))
  results <- c(results, "PASS  Test 3: every district has totenrl > 0")

  stopifnot(n_distinct(df$sedalea) == nrow(df))
  results <- c(results, "PASS  Test 4: all sedalea district ids are unique")

  n_expl <- sum(df$split == "exploration")
  n_conf <- sum(df$split == "confirmation")
  stopifnot(n_expl + n_conf == nrow(df))
  results <- c(results, sprintf(
    "PASS  Test 5: split adds up (exploration=%d, confirmation=%d)",
    n_expl, n_conf
  ))

  cat(paste(results, collapse = "\n"), "\n")
  cat(sprintf("\n%d/5 checks passed.\n", length(results)))
}

run_checks(sample_df)
cat("Done. Wrote seda_2018_srs / _exploration / _confirmation to data/processed/.\n")
