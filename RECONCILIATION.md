# Reconciling the RPubs demos with the drafted chapters

## What I looked at

Your RPubs profile has 13 MLM documents, all published in the fall of 2020: eleven demonstrations, plus content review keys for Modules 1 and 5. There is no Module 6 demonstration, which is the one chapter with no prior version to reconcile against.

I read three of them closely (Module 3, Module 5, and the profile listing) and used those to characterize the differences. I have not yet read Modules 1, 2, 4, 7, 8a, 8b, 9, 10, or 11 in detail. `archive_rpubs.R` in this folder downloads all 13 and recovers the original `.Rmd` source where RStudio embedded it, which is the sensible first step regardless of what we decide.

One timing note: Posit has announced that RPubs retires in June 2027, with published documents readable through December 31, 2031. That is not urgent, but it is the second Posit hosting service to get an end date in a year, and it argues for getting these into a repository you control.

## The core asymmetry

Your demos and my chapters have opposite strengths, and this is the whole basis for the proposal.

**Your code ran.** Every model in those documents was fit, every number printed, every warning surfaced. Module 5 shows a singular fit with an intercept-slope correlation of exactly -1.00, and it shows it because that is what the data did. That is ground truth, and it is the thing I cannot manufacture: my chapters 5 through 11 have never been executed.

**My chapters explain more.** They say what a variance component means, why a random slope is substantively interesting, what an ICC of .18 implies for a reader, and where an interpretation would go wrong. Your demos are terse by design, because you were talking over them on video.

The merge should therefore treat your code as the spine and my prose as connective tissue, not the reverse. Where we disagree about code, you win by default, because your version has evidence behind it.

## Substantive differences found so far

**Estimation method.** You fit with `REML = FALSE` throughout. I wrote `REML = TRUE`. This is not cosmetic: it changes the variance estimates and therefore the ICC. Your Module 3 reports τ₀₀ = 8.553, σ² = 39.148, ICC = .1793, and those are the numbers students will have seen in the video. I recommend adopting ML across the book for consistency with your materials, with a short note explaining that REML is generally preferred for variance estimates while ML is required for comparing models that differ in fixed effects. That note is worth having anyway, since Chapter 8 needs ML for the polynomial comparison.

**Random slope syntax.** You write `(TSIG | COMPID)`. I write `(1 + closeness_pre_c | strs3)`. These are identical to R. Yours is more compact, mine is more explicit about the intercept being estimated too. Worth picking one and using it everywhere; I lean toward the explicit form for a first course, but this is genuinely your call.

**Descriptives package.** You use `Hmisc::describe()` and `Hmisc::label()` to attach variable labels, then show how `summary()` output changes once factors are created. I used `psych::describe()`. Your version is better pedagogy for this audience, because the labeling workflow maps onto what Stata users already do, and the before-and-after `summary()` is a genuinely nice beat.

**Interaction visualization.** You use `interplot::interplot()`. I use `ggeffects::ggpredict()`. `interplot` is thinly maintained now; `ggeffects` is active and handles a wider range of models. I would switch, but the plot your students saw is the `interplot` one.

**Factor labeling idiom.** You use `as_factor()` followed by assigning `levels()`. I specify labels inside `factor()`. Yours is fewer keystrokes and relies on the Stata labels traveling with the file; mine is explicit and survives a file without labels. Minor.

**Terminology.** You call the HSB sectors Public and **Parochial**. I wrote Catholic in Chapter 2. Yours is the term students heard.

## Dataset differences, which are the bigger issue

This is the finding that most affects the plan. There are now three sources that need to agree, and they currently do not.

| Module | Your RPubs demo | Assignment | My chapter |
|---|---|---|---|
| 1 | not yet checked | `hsb2.dta` | `hsb2.dta` |
| 2 | not yet checked | `nlsw88.dta` | `nlsw88.dta` |
| 3 | `hsbmerged.csv` | `hsbmerged` | `hsbmerged.csv` |
| 4 | `lq2002.csv` | `strs_mlm_wide` | `lq2002.csv` |
| 5 | **`lq2002.csv`** | `expanded_strs_no_miss` | **`expanded_strs_no_miss`** |
| 6 | no demo exists | `expanded_strs_no_miss` | `expanded_strs_no_miss` |
| 7–11 | not yet checked | various | matches assignments |

Module 5 is the clear conflict. Your demo teaches random slopes and cross-level interactions on the Army data, continuing directly from Module 4. My chapter teaches the same material on Best in Class. Your continuity is pedagogically stronger: students already know `lq2002` from the previous week, so the new concept arrives without a new dataset attached to it. Your cross-level interaction is also more elegant than mine, testing `TSIG` against `GTSIG`, the same construct at two levels, which makes the idea of a cross-level interaction almost self-explaining.

I would revert Chapter 5 to `lq2002` and keep my Best in Class material as a short applied section at the end, or move it into Chapter 6.

## Things in your demos that should be carried forward

These are teaching moves in your material that I did not have and that are worth preserving:

- The "Data Management Tip of the Week" pattern, particularly computing cluster means with `group_by` + `mutate` + `ungroup` and then verifying against the aggregates already in the file. Showing that the built-in `GTSIG` matches the `gtsig` you just computed is a small thing that builds real confidence.
- `summary()` before and after factor conversion, which makes the factor point visible rather than asserted.
- `modelsummary(models, output = 'msum.html')` as a way to get a table into Word. Students ask about this every term.
- Your habit of restating the substantive question in plain language before interpreting output, for instance "is there an interaction between how I feel about the importance of my job, and how my peers feel about theirs?"

## Proposed approach

**Phase 1: archive.** Run `archive_rpubs.R`. This gets all 13 documents and their recovered source into `rpubs_archive/`. Do this first regardless of anything else, and commit it to the repository.

**Phase 2: reconcile chapter by chapter, code first.** For each chapter, in order:

1. Open the corresponding recovered `.Rmd` next to the drafted `.qmd`.
2. Replace my model code with yours wherever they differ, since yours is verified. Keep the dataset your demo used.
3. Keep my prose, adjusting any numbers it references to match your output.
4. Modernize only where there is a specific reason: `stargazer` to `modelsummary` where it still appears, `interplot` to `ggeffects`, and adding `performance::icc()` as a check alongside your by-hand calculation rather than instead of it.
5. Render, and confirm the numbers match what your RPubs page shows. Where they do not, the difference is a real change in package behavior since 2020 and is worth a footnote.

That last step is the quality control I have been missing. Your published output gives me an answer key for chapters 1 through 5, 7 through 11.

**Phase 3: fill the gaps.** Chapter 6 has no prior demo, so it stays as drafted and needs the closest review. Modules 8a and 8b are separate demos that I merged into one chapter, so decide whether to split it back.

**Order of work.** I would go 3, 4, 5 first, since those are the conceptual core and where I have both your verified code and the clearest sense of the differences. Then 1 and 2, then 7 through 11, then 6 last.

## What I need from you

Three decisions before I start:

1. **ML or REML** as the book default. I recommend ML, matching your demos.
2. **Chapter 5 dataset**: revert to `lq2002` as your demo has it, or keep Best in Class to match the assignment?
3. **Whether to preserve the 2020 numbers exactly.** If a package has changed behavior since then, do you want the book to show the current output, or to match what students saw on RPubs? I recommend current output with a note where it differs meaningfully.
