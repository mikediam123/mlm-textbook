# Change log

A record of how the Quarto book differs from the original bookdown project and from the 2020 RPubs demonstrations, and why. Kept so that when a number in the book does not match a number in an old handout or video, the reason is findable.

---

## 2026-08-15 — Decisions applied

Three decisions were made and implemented across the book: maximum likelihood as the default estimator, `lq2002` as the Chapter 5 dataset, and current package output rather than preserved 2020 output.

### 1. Estimation: ML everywhere

**Changed:** `REML = TRUE` replaced with `REML = FALSE` in 37 model calls across chapters 3, 4, 6, 7, 8, 10, and 11. Chapter 5 was rewritten and uses ML throughout. Chapter 9 is unaffected, since `glmer()` does not take a `REML` argument.

**Why:** Matches the 2020 RPubs demonstrations, which used ML throughout. Also means model comparisons are valid without silent refitting, and the variance components on one page match those on the next.

**Consequence:** Variance components and ICCs will differ slightly from a REML fit. For the Module 3 null model this reproduces the published values: τ₀₀ = 8.553, σ² = 39.148, ICC = .1793.

**Added:** A callout in Chapter 3 explaining the ML/REML distinction, when each is appropriate, and noting that Chapter 11's 17 schools is the one place where REML deserves consideration for a final reported model.

### 2. Chapter 5 dataset: back to `lq2002`

**Changed:** Chapter 5 rewritten from scratch. Was Best in Class (`expanded_strs_no_miss`); now the Gavin and Hofmann Army data (`lq2002.csv`), following the Module 5 RPubs demonstration.

**Why:** Continuity. Students meet `lq2002` in Chapter 4, so the new concept arrives without a new codebook attached. The demo's cross-level interaction, `TSIG` against `GTSIG`, is also a cleaner illustration than the version drafted against Best in Class, because it tests the same construct at two levels.

**Side benefit:** Chapter 5 now renders without adding any data file, since `lq2002.csv` ships with the project. Chapters 3, 4, and 5 all build out of the box.

**Material carried over from the RPubs demo:**

- The cluster-means section (`group_by` → `mutate` → `ungroup`), including verifying the computed `gtsig` against the `GTSIG` already in the file
- Model sequence: random intercept, `(TSIG | COMPID)`, `(TSIG + LEAD | COMPID)`, then the centered cross-level interaction
- The framing question, "is there an interaction between how I feel about the importance of my job, and how my peers feel about the importance of theirs?"
- `modelsummary()` export to a file openable in Word

**Material added:**

- An `ungroup()` warning, since a grouped data frame stays grouped and silently affects later operations
- An extended reading of the singular fit, including that a correlation of exactly −1 is the model reporting exhaustion rather than a finding about the Army
- `model.2b` with uncorrelated random effects, `(1 | COMPID) + (0 + TSIG | COMPID)`, as the standard response to singularity
- A note that centering changes only the intercept, verifiable by comparing model.1 to model.4
- Boundary-of-parameter-space caveat on interpreting `ranova()` p-values
- A closing pointer to the Module 5 content review, which uses Best in Class rather than these data

**Best in Class material:** not lost. Chapter 6 works with `expanded_strs_no_miss` directly.

### 3. Package changes since 2020

Current package behavior is shown rather than 2020 output. Where the difference is meaningful, the book says so.

| Then | Now | Note in book? |
|---|---|---|
| `lmerTest::rand()` | `ranova()` | Yes, callout in Ch. 5 |
| `interplot::interplot()` | `ggeffects::ggpredict()` | Yes, callout in Ch. 5 |
| `stargazer` | `modelsummary` | Yes, index + Ch. 2, 4 |
| `Hmisc::describe()` | `psych::describe()` | No; see open items |
| `%>%` | `\|>` | Mentioned in Ch. 1 |
| `read_csv()` column spec message | Quieter output | No |

**`rand()` → `ranova()`:** renamed in lmerTest. The old name may still work but is no longer documented. Students following an old handout will hit this.

**`interplot` → `ggeffects`:** `interplot` has seen little maintenance. `ggeffects` covers a wider range of models and is actively developed. The plot answers the same question.

**`stargazer` → `modelsummary`:** `stargazer` is effectively unmaintained and can fail on current R. The Module 4 and 5 RPubs demos had already moved to `modelsummary`, so this is consistent with where the course was heading.

**Expect small numeric differences.** lme4's optimizer defaults have changed since 2020, so estimates may differ in the third or fourth decimal place from the published RPubs output. Convergence and singularity messages are also more prominent now than they were, which means models that fit quietly in 2020 may now print warnings without anything having actually changed.

---

## Render-error fixes

Logged as chapters are executed for the first time. Each entry is a place where drafted code failed against the real data.

### Chapter 6 — over-specified random effects halted the render

**Error:** `number of observations (=828) <= number of random effects (=966) for term (1 + conflict_pre_c + closeness_pre_c | strs3)`

**Cause:** The chunk demonstrates a model that cannot be identified, which is the point. But `lmer()` raises a hard error rather than a warning, and knitr stops the render on errors by default.

**Fix:** Added `#| error: true` to the chunk so the error renders as visible output. Removed the trailing `summary()` call, which could never execute.

**Bonus:** The real error message is better teaching material than the prose originally drafted around it. The arithmetic is explicit and checkable: 322 teachers × 3 random effects = 966 parameters against 828 observations. The chapter now walks through that calculation and recommends doing it before fitting any complex random structure.

### Chapter 10 — Shapiro-Wilk sample larger than the analysis sample

**Error:** `cannot take a sample larger than the population when 'replace = FALSE'` at `sample(aug$std_resid, 5000)`

**Cause:** The code assumed the model was fit on more than 5,000 observations, based on `projectSTAR.dta` having 6,000+ rows. It was not. `lmer()` drops cases missing on the outcome or any predictor, and with `gkselfconcraw`, `gkclasstype`, and `gkthighdegree` in the model the analysis sample fell below 5,000.

**Fix:** The Shapiro-Wilk call now branches on `nrow(aug)`, sampling only when the residual vector exceeds the 5,000-observation limit the test accepts.

**Also added:** A short section contrasting `nrow(star)` with `nrow(aug)`, making listwise deletion visible rather than incidental. This is a real teaching point that the error surfaced: the analysis N is not the file N, `lmer()` reduces it silently, and two models fit on different subsamples cannot be validly compared. Softened a nearby sentence that asserted "thousands of observations."

**Preventive:** Chapter 8's spaghetti plot used a fixed `sample(..., 30)`. Changed to `min(30, length(all_ids))` so it degrades rather than failing if the sample is ever smaller than expected.

### Chapter 10 — cluster vector longer than the analysis sample

**Error:** `arguments must have same length`, raised inside `tapply()` under `clubSandwich::coef_test(m, vcov = "CR2", cluster = star$gktchid)`

**Cause:** The same listwise deletion, appearing a second time in the same chapter. `star$gktchid` has one entry per row of the dataset; the model used only complete cases. clubSandwich could not align the cluster vector with the model's residuals.

**Fix:** Dropped the `cluster` argument. `coef_test()` reads the grouping structure from the fitted `lmerMod` object, which already knows which rows it used.

**Also added:** A callout explaining why the obvious version fails, showing the `model.frame(m)$gktchid` alternative for cases where the cluster must be passed explicitly, and generalizing the lesson: once a model is fit, prefer `model.frame()`, `augment()`, or the model object over the original data frame, because anything derived from the source data risks being the wrong length.

**Note:** Both Chapter 10 errors have the same root cause. Chapter 10 is where listwise deletion becomes unavoidable because that model carries three predictors, and the chapter now teaches it in two places rather than tripping over it.

### Chapter 10 — `tibble()` silently dropped a NULL column

**Error:** `object 'gktchid' not found`, raised by `pull()` two chunks after the cause.

**Cause:** `cook_df` was built with `gktchid = names(cooks)`. But `cooks.distance()` on an `influence.ME` object returns a matrix whose labels live in `rownames()`, so `names()` returned `NULL`. `tibble()` drops `NULL` columns without warning, producing a one-column data frame. Everything using only `cooks_d` continued to work, including the Cook's distance plot, so the failure surfaced well downstream of the mistake.

**Fix:** Read the labels from `rownames()`, with fallbacks to `names()` and then a positional index. Added a `str(cooks)` call so the object's actual structure is visible before a data frame is built from it.

**Also fixed:** `filter(!(gktchid %in% flagged))` compared numeric IDs in the data against character labels from `rownames()`. Now explicitly `as.character(gktchid) %in% flagged`. Added `length(flagged)` and a before/after row count so the trimming is visible rather than assumed.

**Also added:** A callout on the general hazard. `tibble()` accepting a `NULL` column silently means a variable can go missing far from where the error appears. The habit worth teaching is to look upstream at where the object was created, and to run `str()` on unfamiliar objects before building data frames from them.

### All remaining chapters aligned to the demonstration handouts

The remaining eight handouts were supplied. Every chapter except 6 now follows its handout's code, with explanation added around it. Verified programmatically: datasets, model object names, and outcome variables all match.

**Corrections to datasets I had guessed wrong.** Four chapters were built on entirely the wrong data:

| Chapter | Was | Now |
|---|---|---|
| 7 | `gktmathss` (math) | `gktreadss` via `read`, with the full `star.clean` recode |
| 8 | `STAR_long.dta` / `STAR_wide.dta` | `egmerged.dta`, Sustaining Effects Study |
| 9 | `school_belonging.csv` | `nsch_2018_topical.dta`, NSCH asthma |
| 10 | `projectSTAR.dta` | `productivity.dta`, state unemployment |

**Chapter 8 split into 8a and 8b**, matching the two handouts and the two content reviews. `08-growth-curves.qmd` removed; `08a-growth-intro.qmd` and `08b-growth-advanced.qmd` added. `_quarto.yml` updated.

**Chapter 4** rebuilt on `MLM_Week_4_Handout.Rmd`: `model.0` through `model.5`, the hardcoded ICC `0.05765/(0.05765 + 1.01668)`, three base R `hist()` calls, explicit `TSIG:LEAD`, and `alpha()`/`scoreItems()` for the scale construction.

**Chapter 5** aligned to `MLM_Module_5_Handout.Rmd`. Notably `ghostile = mean(GHOSTILE)`, which I had written as `mean(HOSTILE)`. Restored `interplot::interplot()` as primary with `ggeffects` offered as a fallback, reversing an earlier substitution now that matching the video takes priority.

**Chapter 7** rebuilt: reading scores, the `star.clean` pipeline with renames and the `mean(gkfreelunch) - 1` proportion trick at classroom and school levels, `(1|schoolid) + (1|classid)` rather than the nesting shorthand, and `(years_exp|schoolid)` for the random slope.

**Chapters 8a and 8b** built on `egmerged.dta`: the `table1` descriptive tables from collapsed student- and school-level frames, `scatter.smooth()`, `broom.mixed::augment()` with `effects = c("ran_pars", "fixed")`, the 50-student subset plots, `pivot_wider` then `pivot_longer`, and the `nlme::lme()` homogeneous and heterogeneous variance pair.

**Chapter 9** rebuilt on NSCH: the `select` → `as_factor` → `table` → `filter` → `rename` → `case_when` cleaning sequence, `glmer(family = binomial)`, the hardcoded logistic ICC with `pi^2/3`, hand-computed odds ratios and predicted probabilities via `exp(x)/(1+exp(x))`, and the hardcoded AIC/BIC comparison.

**Chapter 10** rebuilt on `productivity.dta`: `year0 = year - 1970`, `pub_cap_1000`, polynomial model sequence, `augment()` diagnostics, `shapiro.test()`, RVF plots plain and colored by year, the Cook's distance plot labelled by state with the `4/816` cutoff, `robustlmm::rlmer()`, and the trimmed-model comparison.

**Chapter 11** aligned: outcome changed from `p7read` to `attain`, added the eleven `label()` calls, the `as_factor()` + `levels()` recodes, three ggplot histograms, hardcoded ICCs for all four models, `model.1` through `model.6`, and `interplot` for the `deprive` × `dadocc` interaction.

**One silent fix.** The Module 10 handout has `linetype = "d  otted"` with a stray space in the Cook's distance chunk, which errors. Corrected to `"dotted"`.

**Explanation added throughout**, without changing code: why `psych::describe()` should be namespaced; what `bind_cols()` assumes; why the `- 1` proportion trick depends on 1/2 coding; the difference between a random slope and a cross-level interaction; why the level-1 variance drops when time enters a growth model; that odds ratios are not probabilities; why `augment()` output should be used instead of the source data; and, in Chapter 7, a warning that `anova(model.4, model.5)` compares models differing in both fixed and random effects.

**Superseded:** the earlier note about aligning only chapters 1–3.

### Chapters 1–3 aligned to the actual demonstration handouts

Dr. Broda supplied the three MLM demonstration handouts (`Video Links and Code Demos/`). All three chapters were rewritten so the book follows the code students see in the videos. Elaboration was added freely; the code spine was not changed.

**Chapter 1** now follows `MLM_Module_1_Handout.Qmd`: tidyverse/psych/haven, `read_dta("descriptive_gss.dta")`, `glimpse()`, `str(gss$satjob7)`, `describe(gss, fast = TRUE)`, `hist(gss$educ)`, `hist(gss$sex, freq = FALSE)`. Base R `hist()` rather than ggplot, matching the handout.

An earlier draft had used the *MVS* Module 1 handout, which covers similar ground on the same dataset but with different variables (`marital`, `childs`) and ggplot rather than base graphics. Corrected.

Elaboration added: what `haven_labelled` means; why the `sex` histogram is uninformative and `table()` is the better tool for a two-category variable; the categorical-variables-stored-as-numbers callout; common error messages.

**Chapter 2** now follows `Module_2_Handout.Rmd` and uses `food.csv`, not `nlsw88.dta`. This was the largest correction: the chapter had been built on entirely different data. Now: tidyverse/ggplot2/broom/skimr, the `rename` → `mutate` → `na.omit` cleaning pipeline, `skim()`, and the four-model sequence `foodreg1` through `foodreg4` ending in the income × children interaction.

Dr. Broda's substantive explanations were preserved: the warning label on `na.omit()`, the mutation joke, the interpretation of each coefficient, and the power caveat on the interaction.

Elaboration added: a row-count check before and after `na.omit()`; why a stable coefficient across models is informative; the distinction between "there is no interaction" and "we did not detect one with 50 families"; the association-versus-causation note.

**Chapter 3** now follows `MLM_Week_3_Handout.Rmd` more closely. Switched from `psych::describe()` to `Hmisc::describe()` with `label()`, adopted the `summary()` before-and-after-factors sequence, and uses the `as_factor()` then `levels()` assignment idiom with Public/Parochial, Male/Female, Non-Minority/Minority. The by-hand ICC now uses the handout's literal `8.553/(8.553 + 39.148)`.

Elaboration added: an `Hmisc`/`dplyr` masking warning; why level-assignment order matters and how to check it; extracting variance components programmatically as a safer alternative alongside the by-hand version; the fixed intercept versus grand mean comparison.

**Deviation, deliberate and flagged:** `rand()` appears as `ranova()`, with a callout noting the rename. Chapter 2 uses `modelsummary` rather than `stargazer`, with a callout explaining why and noting the video shows `stargazer`.

**Relocated:** the "few categories do not make a clustering variable" material, written for the old nlsw88 chapter 2, now lives in Chapter 3 as a callout at the point where `(1 | schoolid)` is introduced. That is a better home, since it answers the question a student has exactly when they first meet the syntax.

### Superseded: Chapter 1 rebuilt on the MVS Module 1 handout

**Changed:** Chapter 1 now follows the Module 1 demonstration handout rather than the version drafted from scratch. Dataset moves from `hsb2.dta` to `descriptive_gss.dta` (General Social Survey 2012, N = 2,765), using `marital`, `sex`, and `childs`.

**Structure follows the handout:** load packages with the note about the Packages menu, load data with the note about the Import Dataset button, `View()` and `glimpse()`, `str()` for variable labels, `describe(fast = TRUE)`, `table()` for categorical variables, `geom_bar()`, then the labelled version with `labs()`.

**Additions kept from the earlier draft:**

- The categorical-variables-stored-as-numbers trap, which lands better on these data than on the previous version, since `marital` and `sex` arrive from Stata as `haven_labelled` and `describe()` reports meaningless means for both
- `as_factor()` for converting labelled Stata variables, with a manual `factor()` fallback
- A `geom_bar()` versus `geom_histogram()` section: bar counts distinct values, correct for `childs`; histogram bins, correct for continuous measures. Includes a demonstration of the information lost by binning a count
- Faceting for group comparison on a shared axis
- The pipe, and the common error messages

**One practical fix:** `View()` opens an interactive window and does nothing useful during a render. It appears in the chapter as the handout has it, but in an `eval: false` chunk with a callout explaining why. Left live, it would produce a confusing failure.

**Consequence:** Chapter 1 no longer matches the Module 1 content review, which uses `hsb2.dta`. Documented in the README alongside the Chapter 4 mismatch.

### Chapter 2 — reworked the clustering section

**Problem:** The chapter used `industry` in `nlsw88` as its example of a clustering variable. With fewer than a dozen industries, this taught the wrong lesson, and it reinforced a misconception students arrive with: that any categorical variable is a candidate for `(1 | group)`.

**Changed:** The section now uses `industry` as a worked example of a variable that is *not* suitable, and explains how to recognize the difference.

The new sequence: count the units, note that a random intercept estimates a variance from as many observations as there are groups, fit the bad model anyway to show that R produces normal-looking output with no warning, then use `confint()` on the variance component to expose how wide the uncertainty actually is.

**Added a callout** with three questions to ask before writing `(1 | something)`:

1. How many units? Under 20, not estimable; 20 to 50, proceed with caution; above 50, solid.
2. Are these units a sample from a population you want to generalize to? Nine industries are the complete set of survey categories, not a sample. The 160 schools in Chapter 3 are a sample.
3. Do you want group-specific effects (fixed) or the variation among groups (random)?

It closes by naming the cases students most often get wrong: sex, treatment condition, region, program type.

**Added:** The correct handling for few categories, `factor(industry)` as a fixed effect, plus a pointer to cluster-robust standard errors as the other route to fixing the inference without estimating a group-level variance.

**Reframed the bridge to Chapter 3.** The chapter now says plainly that `nlsw88` is a single-level dataset for our purposes, and that seeing clustering modeled properly requires data with many level-2 units. This is more honest than the previous version, which implied the wage data supported a multilevel analysis it cannot.

**Removed:** the industry mean-wage bar chart, which visually implied industry was the clustering variable to use.

### SETUP.md corrections around git

**Changed:** The remote URL in step 4 now uses the SSH form, `git@github.com:USER/repo.git`, rather than HTTPS. The original HTTPS instruction is a dead end for anyone authenticating with an SSH key, because an HTTPS remote ignores SSH keys and prompts for credentials instead.

**Added:** An authentication section covering 1Password as the SSH agent (enabling it, the `IdentityAgent` line for `~/.ssh/config`, registering the public key on GitHub), the `ssh -T git@github.com` test, and a personal access token fallback.

**Added earlier in step 4:** A folder-verification step before `git init`, since running it in the wrong directory creates a repository that tries to track everything beneath it. Includes the `git status` sanity check and how to back out with `rm -rf .git`. Also notes that the project folder name contains spaces, so manual `cd` requires quoting.

**Added:** A pointer to RStudio's Git pane, which appears after the project is reopened post-`init` and removes the need for the command line in normal use.

### Automated the .nojekyll file and the CDN check

**Added:** `_postrender.R`, registered under `project: post-render` in `_quarto.yml`. It runs after every render and does two things.

First, it creates `docs/.nojekyll` if missing. Doing this by hand is awkward on macOS, since Finder hides and resists dotfiles, and a hand-made file can be lost whenever `docs/` is regenerated. Automating it removes a step that silently breaks the published site's styling when forgotten.

Second, it scans the rendered HTML for `polyfill.io` references and warns if any appear, so a future config change cannot quietly reintroduce the CDN dependency.

**Updated:** `SETUP.md` step 3 now says the file is automated, with manual fallbacks (`file.create()` in the Console, `touch` in the Terminal) and a note that `ls` will not show the file without `-a`.

### Added student companion files

**Added:** `make_student_files.R`, which generates two R files per chapter into `student_files/`, plus a zip for Canvas.

- `code/` holds the complete code from each chapter, prose stripped, section headers preserved as comment banners. This is the reference and catch-up copy.
- `followalong/` holds the same file with model-fitting calls commented out and marked YOUR TURN, so students type the model syntax themselves while watching the video. The book's version sits directly below, commented, so nobody gets stranded.

Both are generated from the `.qmd` files and cannot drift out of sync. Regenerate rather than editing by hand.

**Also added:** `code-tools: true` in `_quarto.yml`, which puts a code menu on every page for viewing the source directly from the website.

**Caveat:** the YOUR TURN rule is a heuristic, matching assignments whose right-hand side calls `lmer`, `glmer`, or `lme`. Review a few generated files before posting.

**Deliberately not done:** handing students the chapter `.qmd` files as-is. They are mostly prose and callouts, which is noise during a video, and a complete runnable file makes following along a matter of pressing Ctrl+Enter.

### Broken images on the published site

**Symptom:** Every plot showed as a broken image icon on GitHub Pages, while the same pages looked correct locally.

**Cause:** My error in the original `.gitignore`. The rule `*_files/` was intended for knitr's intermediate folders at the project root, but with no leading slash it matches at any depth, including `docs/01-getting-started_files/` and every other figure folder Quarto generates. All 39 rendered plots were silently excluded from every commit. `git check-ignore -v docs/01-getting-started_files` reported `.gitignore:3:*_files/`, which confirmed it.

The local/published split is the diagnostic signature: the files exist on disk, so local viewing works, and they were never committed, so the published site has nothing to serve.

**Fix:** Anchored the rules to the project root as `/*_files/` and `/*_cache/`, so knitr intermediates are still ignored while the output figures are tracked. Also added `/_freeze/` explicitly.

**Also added:** A troubleshooting entry in `SETUP.md` describing the symptom and the `git check-ignore -v` check, since this failure mode gives no error message anywhere.

### Rendered pages referenced polyfill.io

**Symptom:** Clicking through the rendered book occasionally produced a login prompt from `polyfill.io`.

**Cause:** Not our code. Pandoc's MathJax template has long injected `<script src="https://polyfill.io/v3/polyfill.min.js?features=es6">` ahead of the MathJax script, and Quarto inherits that template. It appeared in the four rendered chapters containing math: 2, 3, 6, and 9.

**Why it matters:** The polyfill.io domain and its GitHub repository were sold in February 2024 to Funnull, a Chinese-operated company. By June 2024 the service was injecting malicious code that redirected mobile visitors to scam and betting sites, affecting several hundred thousand sites. Namecheap suspended the domain on 27 June 2024, and the U.S. Treasury later sanctioned Funnull. The immediate risk is therefore gone, and the odd login prompt is a suspended-domain artifact rather than an active attack. But a page we hand to students should not be requesting scripts from a domain with that history.

**Fix:** Set `html-math-method: katex` in `_quarto.yml`. KaTeX renders this book's math without the polyfill shim, and is faster besides.

**Also added:** A pre-publication check in `SETUP.md` (`grep -rl "polyfill" docs/`) and a note that any domain the rendered pages load from is a dependency students inherit.

### Missing package dependencies

**Symptom:** `check_model()` failed until `see` was installed. `influence.ME` was also not installed.

**Fix:** Added `see` to the package lists in `index.qmd` and `SETUP.md`, with a note that nothing loads it directly, so its absence is easy to misdiagnose. Added `influence.ME` and `clubSandwich` to the `index.qmd` list, which had omitted them, with a note that they are needed only for Chapter 10.

---

## Earlier — Migration from bookdown

**Framework:** bookdown → Quarto. Driven by Posit sunsetting bookdown.org hosting on 31 January 2026 (now a read-only archive), and by the course adopting Quarto as the assignment submission format.

**Hosting:** bookdown.org → GitHub Pages, serving from `docs/`.

**Location:** the project lives in a plain local folder rather than Google Drive, because Drive sync and git corrupt each other's `.git` directory. The original bookdown folder is untouched as an archive.

**Chapters:** 2 partial chapters → 11, numbered to match the course modules.

**Cleanups to the two existing chapters:**

- Removed the default bookdown template boilerplate that shipped with the skeleton: the `iris` table, the `pressure` plot, "This is a _sample_ book written in Markdown," and the placeholder chapters (`02-literature.Rmd`, `03-method.Rmd`, and so on)
- Removed a hardcoded `setwd()` pointing at a 2019 Google Drive path, which would have broken on any other machine
- Removed a stray fragment of Stata code (`mixed HOSTILE TSIG LEAD GTSIG || COMPID:`) left in the Week 4 file
- Fixed malformed HTML in `_output.yml` (`<li><a href="./"><MLM Class Textbook</a></li>`)

**Chapters 1 and 2 datasets:** originally drafted against `hsbmerged`; rewritten to use `hsb2.dta` and `nlsw88.dta` so the demonstrations match the Module 1 and Module 2 content reviews. Variable lists were verified against the UCLA codebook and the Stata dataset documentation before writing.

**Chapter 4 dataset:** deliberately still differs from the Module 4 assignment. The chapter uses `lq2002` (matching Garson Chapter 6 and the original demo) while the assignment uses Best in Class. Documented in the README so it does not later look like an oversight.

**Terminology:** HSB school sectors are labeled Public and Parochial, matching the RPubs demos. An earlier draft used "Catholic."

---

## Open items

- **Chapters 5 through 11 have never been executed.** They were drafted against variable names taken from the assignment documents. The first render is a proofreading pass, not a formality.
- **Chapter 6 has no prior demonstration.** There is no Module 6 document on RPubs, so it is the one chapter with no verified code to reconcile against, and it needs the closest review.
- **Chapters 1, 2, 4, 7, 8a, 8b, 9, 10, and 11 have not yet been read against their RPubs originals.** Only Modules 3 and 5 were reconciled in detail. Run `archive_rpubs.R`, then work through the rest in the order proposed in `RECONCILIATION.md`.
- **`Hmisc::describe()` vs `psych::describe()`.** The demos use `Hmisc`, along with `label()` to attach variable labels, and show how `summary()` output changes after factor conversion. That is arguably better for students coming from Stata. The book currently uses `psych`. Unresolved.
- **Random slope syntax.** The demos use `(TSIG | COMPID)`; the drafted chapters mostly use the explicit `(1 + x | group)`. Chapter 5 now shows both and notes they are equivalent. Worth settling on one convention.
- **Modules 8a and 8b are separate demos** but were merged into a single Chapter 8. Decide whether to split.
- **Verify the Fall 2026 academic calendar** against VCU's official dates before publishing the syllabus.
