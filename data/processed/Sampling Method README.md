## Motivation
 
Our initial proposal treated all U.S. school districts as an i.i.d. sample but after some discussion and feedback on our
proposal it was determined that districts within the same state are not independent as they share
state-level funding formulas, testing standards, and policy environments. Making residuals for
same-state districts likely to be correlated. Using all ~13,000 districts as-is would overstate the
effective sample size and understate standard errors on any regression run against the full
population.
 
Rather than fix this problem through an argument/parameter in our code, (which might be valid in some instances but doesn't reduce the underlying correlation in the data itself), we
chose to draw a **state-proportional stratified random sample of ~400 districts** before doing
any modeling. This shrinks the number of same-state district pairs in our analysis dataset by
roughly 30x relative to the full population, meaningfully reducing (though not fully eliminating)
the practical impact of within-state clustering, while preserving a nationally representative mix
of districts across states.
 
## Data Prep
 
1. Downloaded SEDA v6.0 district-level achievement (`seda_geodist_annual_cs_6.0`) and covariate
   (`seda_cov_geodist_annual_6.0`) files, pre-filtered to `year == 2018`.
2. The achievement file contains multiple rows per district: an "all students" mean, separate
   race/gender/ECD subgroup means, and race/gender/ECD achievement gaps, all in the same file.
   We filtered to `subgroup == "all" & gap == FALSE` to keep exactly one district-level mean
   test-score row per district (11,139 rows).
3. Inner-joined the filtered achievement rows to the covariate file (12,690 rows) on
   `sedalea`, `year`, `fips`, and `stateabb`.
   - Result: 11,139 matched districts.
   - **1,551 covariate-file districts (12.2%) were dropped** because they had no row at all in
     the achievement file for 2018, in any subgroup. Likely SEDA reported no test-score
     estimate for that district that year (e.g., too few tested students, no grades 3-8
     enrolled, the seda_documentation file has more information on their methodology). This is a limitation of the data itself and we've opted to only use
     data that would fit it. 
4. This produced our filtered raw dataset (`seda_2018.csv`, 11,139 districts x 115 columns),
   which serves as the sampling frame below.


## Stratified Sampling Procedure
 
**Field we will stratify on:** U.S. state (`stateabb`), including DC, consistent with SEDA's own state
classification.
 
**Target sample size:** ~400 districts total.
 
**Allocation method:** proportional allocation with a floor of 1 district per state.
 
1. Counted the number of districts per state in the 11,139-district sampling frame.
2. Computed each state's current proportion of districts per state, 'stored as raw_alloc',
   `raw_alloc = n_districts_in_state / 11,139 * 400`.
3. Took the floor of each state's proportional representation, then distributed the small number of
   leftover slots (lost to flooring) to the states with the largest fractional remainders,
   thus allocations sum to, approximately, 400 
4. Applied a floor of 1 district per state/DC so every state is represented in the sample,
   even states whose population share would otherwise round to 0. This is an intentional
   deviation from assigning based on pure proportionality as we'd like to ideally have 100% state coverage
5. Capped each state's allocation at its actual number of available districts (relevant only
   for the smallest states).

**Random draw:** using a fixed random seed (`set.seed(42)`, recorded here for
reproducibility), we randomly sampled the allocated number of districts within each state,
without replacement, from the sampling frame.
 
**Result:** a data frame of sampled district IDs (`sampled_district_ids.csv`), which we then
used to filter the full 11,139-district dataset down to our final analysis sample
(`seda_2018_sample.csv`), preserving every original column for just the sampled districts.
 
## Potential Issues
 
- Proportional-by-state sampling reduces but does not eliminate within-state correlation:
  states with larger allocations (e.g., more populous states) still contribute multiple
  districts to the final sample, and those districts remain subject to shared state-level
  policy effects. We treat the sample as *approximately* independent for CLT purposes rather
  than claiming strict i.i.d., and may additionally report state-clustered standard errors as
  a robustness check in our final model.
- The floor-of-1-per-state rule means our final sample is not perfectly proportional to
  state population share; smaller states are slightly over-represented relative to pure
  proportional allocation, in exchange for full national coverage.
- The 1,551 districts dropped for lack of achievement data are not missing at random with
  respect to district size (very small districts are more likely to be suppressed) — this is
  a limitation of the underlying SEDA data, not our sampling procedure, but it should be kept
  in mind when interpreting how representative our final sample is of the smallest districts

 
