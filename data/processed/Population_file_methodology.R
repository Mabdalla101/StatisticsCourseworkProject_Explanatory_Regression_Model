#This is the exact code used to join the two datasets in raw such that we have a population file, coded in RStudio

library(tidyverse)

achievement <- read_csv("/Users/mohammedabdalla/Downloads/seda_geodist_2018.csv")
covariates  <- read_csv("/Users/mohammedabdalla/Downloads/seda_cov_geodist_2018.csv")


# (drop race/gender/Etc subgroup rows and gap rows, we want the aggregate):
achievement_all <- achievement %>%
  filter(subgroup == "all", gap == FALSE)  

# Join on shared unique ids
seda_2018 <- achievement_all %>%
  inner_join(
    covariates,
    by = c("sedalea", "year", "fips", "stateabb"),
    suffix = c("", "_cov")
  )


nrow(achievement_all)  
nrow(seda_2018)  
write_csv(seda_2018, "/Users/mohammedabdalla/Downloads/seda_2018.csv")

      
