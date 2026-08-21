# Applied Multilevel Modeling in R

An online companion to EDUS 664, Multilevel Modeling, at Virginia Commonwealth University. Each chapter works through the R code for one module of the course.

Built with [Quarto](https://quarto.org). The rendered site lives in `docs/` and is published through GitHub Pages.

## Contents

Chapters are numbered to match the course modules. With one exception, each chapter uses the same dataset as that module's content review, so the demonstration and the assignment line up.

Every chapter except 6 follows the corresponding demonstration handout in `Video Links and Code Demos/`, so the book matches the code students see in the videos. Module 6 has no handout, so that chapter was written from scratch.

| Chapter | Topic | Data | Source |
|---|---|---|---|
| 1 | Getting Started with R and RStudio | `descriptive_gss.dta` | `MLM_Module_1_Handout.Qmd` |
| 2 | Review of Linear Regression | `food.csv` | `Module_2_Handout.Rmd` |
| 3 | Intro to MLM and the Null Model | `hsbmerged.csv` | `MLM_Week_3_Handout.Rmd` |
| 4 | Conditional Random Intercept Models | `lq2002.csv` | `MLM_Week_4_Handout.Rmd` |
| 5 | Random Slope Models | `lq2002.csv` | `MLM_Module_5_Handout.Rmd` |
| 6 | Goodness-of-Fit and Effect Sizes | `expanded_strs_no_miss.csv` | no handout, written fresh |
| 7 | Three-Level Models | `projectSTAR.dta` | `MLM_Module_7_Handout.Rmd` |
| 8a | Intro to Growth Models | `egmerged.dta` | `MLM_Module_8_Handout_Part_1.Rmd` |
| 8b | Advanced Growth Models | `egmerged.dta` | `MLM_Module_8_Handout_Part_2.Rmd` |
| 9 | Binary and Generalized Linear Mixed Models | `nsch_2018_topical.dta` | `MLM_Module_9_Handout.Rmd` |
| 10 | Checking Assumptions for MLMs | `productivity.dta` | `MLM_Module_10_Handout.Rmd` |
| 11 | Cross-Classified Linear Mixed Models | `scotland.dta` | `MLM_Module_11_Handout.Rmd` |

Module 8 is split into two chapters, matching the two handouts and the two content reviews.

Chapters and content reviews often use different datasets. That is by design: the demonstration teaches the mechanics on one dataset, and the assignment applies them to another.

## Data files

Most datasets are already in this folder. Three still need to be copied in before the book will render:

- `egmerged.dta` (chapters 8a and 8b)
- `nsch_2018_topical.dta` (chapter 9)
- `productivity.dta` (chapter 10)

See `SETUP.md`.

## Rendering

```bash
quarto render
```

Or click **Render Book** in RStudio's Build pane.

## License

Course materials by Michael Broda, Ph.D. Data are used under the terms of their original sources, which are listed in the References chapter.
