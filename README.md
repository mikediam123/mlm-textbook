# Applied Multilevel Modeling in R

An online companion to EDUS 664, Multilevel Modeling, at Virginia Commonwealth University. Each chapter works through the R code for one module of the course.

Built with [Quarto](https://quarto.org). The rendered site lives in `docs/` and is published through GitHub Pages.

## Contents

Chapters are numbered to match the course modules. With one exception, each chapter uses the same dataset as that module's content review, so the demonstration and the assignment line up.

| Chapter | Topic | Data | Matches module |
|---|---|---|---|
| 1 | Getting Started with R | `hsb2.dta` | yes |
| 2 | Review of Regression | `nlsw88.dta` | yes |
| 3 | The Null Model | `hsbmerged.csv` | yes |
| 4 | Conditional Random Intercept Models | `lq2002.csv` | no, see below |
| 5 | Random Slope and Coefficient Models | `expanded_strs_no_miss` | yes |
| 6 | Goodness-of-Fit and Effect Sizes | `expanded_strs_no_miss` | yes |
| 7 | Three-Level Models | `projectSTAR.dta` | yes |
| 8 | Longitudinal and Growth Curve Models | `STAR_long.dta`, `STAR_wide.dta` | yes |
| 9 | Generalized Multilevel Models for Binary Outcomes | `school_belonging.csv` | yes |
| 10 | Assessing Assumptions | `projectSTAR.dta` | yes |
| 11 | Cross-Classified Models | `scotland.dta` | yes |

Chapter 4 deliberately uses different data from the Module 4 assignment. The chapter demonstrates a random intercept model on soldiers nested in companies, matching Garson Chapter 6, while the assignment uses the Best in Class trial. Seeing the same technique applied outside education is useful transfer practice, and students meet the Best in Class data in chapters 5 and 6.

## Data files

`hsbmerged.csv` and `lq2002.csv` are included in this repository, so chapters 3 and 4 render as-is. Every other chapter needs a course dataset copied into this folder first. See `SETUP.md`.

## Rendering

```bash
quarto render
```

Or click **Render Book** in RStudio's Build pane.

## License

Course materials by Michael Broda, Ph.D. Data are used under the terms of their original sources, which are listed in the References chapter.
