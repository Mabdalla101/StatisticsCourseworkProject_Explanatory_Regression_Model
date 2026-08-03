library(dplyr)
library(readr)
library(lmtest)
library(sandwich)
library(stargazer)

seda_sample <- read_csv("~/Downloads/datasci-203-26-section6-summer-C-main/data/processed/seda_2018_sample.csv", show_col_types = FALSE)

ses_vars <- c("cs_mn_avg_ol", "povertyall", "lninc50all", "baplusall",
              "unempall", "snapall", "single_momall")

# 6 districts are missing all SES covariates; drop before splitting
model_df <- seda_sample %>% filter(if_all(all_of(ses_vars), ~ !is.na(.)))
cat(sprintf("Districts: %d raw -> %d after dropping missing predictors\n",
            nrow(seda_sample), nrow(model_df)))

set.seed(42)
n <- nrow(model_df)
explore_n <- floor(0.30 * n)
shuffled <- sample(seq_len(n))
model_df$split <- "confirmation"
model_df$split[shuffled[1:explore_n]] <- "exploration"

# stargazer needs a plain data.frame, not a tibble, or it can throw
# "missing value where TRUE/FALSE needed" during table formatting
explore <- as.data.frame(model_df %>% filter(split == "exploration"))
cat(sprintf("Exploration set: %d districts\n", nrow(explore)))[8:16 PM]```{r modeling-fit}
m1 <- lm(cs_mn_avg_ol ~ povertyall, data = explore)

m2 <- lm(cs_mn_avg_ol ~ povertyall + lninc50all + baplusall +
           unempall + snapall + single_momall, data = explore)

m3 <- lm(cs_mn_avg_ol ~ povertyall + I(povertyall^2) + lninc50all +
           baplusall + unempall + snapall + single_momall, data = explore)

# Heteroskedasticity-robust standard errors
robust_se <- function(model) sqrt(diag(vcovHC(model)))
```

```{r modeling-table, results='asis'}
#| tbl-cap: Regression Results.
stargazer(m1, m2, m3,
  header = FALSE,
  se = list(robust_se(m1), robust_se(m2), robust_se(m3)),
  type = if (isTRUE(knitr::is_latex_output())) "latex" else "html",
  dep.var.labels = "Test Performance (SD units from national mean)",
  covariate.labels = c("Poverty Rate", "Poverty Rate Squared", "Log Median Income",
                        "% Bachelor's Degree+", "Unemployment Rate",
                        "% SNAP Recipients", "% Single-Mother Households"),
  digits = 2,
  omit.stat = c("f", "ser"),
  star.cutoffs = c(0.05, 0.01, 0.001)
)