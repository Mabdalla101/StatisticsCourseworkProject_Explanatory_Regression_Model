#NOTE: In my personal code, our population dataset was named seda_2018, in the github for documentation i had named it as seda_population_2018 for transparency. If you'd like to run this code yourself you'd only need to download the seda population file in this directory, read it in with read_csv() and title it as 'seda_2018'

library(tidyverse)
library(writexl)
library(purrr)

set.seed(42)  # fixed seed for reproducibility -- record this value in the appendix

TARGET_TOTAL <- 400


# Step 1: sampling frame -- one row per district, with its state
district_state <- seda_2018 %>%
  distinct(stateabb, sedalea)

# Step 2: count districts per state, compute proportional allocation
state_counts <- district_state %>%
  count(stateabb, name = "n_districts") %>%
  mutate(
    raw_alloc = n_districts / sum(n_districts) * TARGET_TOTAL,
    n_sample  = floor(raw_alloc),
    remainder = raw_alloc - n_sample
  )

# hand out leftover slots (from flooring) to states with the largest fractional remainder
n_leftover <- TARGET_TOTAL - sum(state_counts$n_sample)

state_counts <- state_counts %>%
  arrange(desc(remainder)) %>%
  mutate(n_sample = n_sample + if_else(row_number() <= n_leftover, 1, 0)) %>%
  mutate(n_sample = pmax(n_sample, 1)) %>%           # floor of 1 district per state/DC
  mutate(n_sample = pmin(n_sample, n_districts)) %>% 
  select(stateabb, n_districts, n_sample)

sum(state_counts$n_sample)  # actual total (won't be exactly 400 due to the floor-of-1 rule)

write_csv(state_counts, "/Users/mohammedabdalla/Downloads/state_sample_allocation.csv")

# Step 3: randomly sample district IDs per state -> data frame of just district IDs
joined <- district_state %>%
  left_join(state_counts %>% select(stateabb, n_sample), by = "stateabb")

sampled_ids <- joined %>%
  group_by(stateabb) %>%
  group_map(~ slice_sample(.x, n = .x$n_sample[1]), .keep = TRUE) %>%
  bind_rows() %>%
  select(stateabb, sedalea)

write_csv(sampled_ids, "/Users/mohammedabdalla/Downloads/sampled_district_ids.csv")

# Step 4: filter the full joined dataset down to just those district IDs -- this is the sample dataset
seda_sample <- seda_2018 %>%
  semi_join(sampled_ids, by = c("stateabb", "sedalea"))

nrow(seda_sample)  # sanity check -- should match sum(state_counts$n_sample)

write_csv(seda_sample, "/Users/mohammedabdalla/Downloads/seda_2018_sample.csv")
