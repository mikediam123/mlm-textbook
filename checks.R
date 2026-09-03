# checks.R --------------------------------------------------------------------
#
# Self-check helpers for EDUS 664 content reviews.
#
# Put this file in the same folder as your assignment, then at the end of your
# document run:
#
#     source("checks.R")
#     check_module(3)
#
# It looks at the objects you have created and tells you whether the mechanics
# are in place: the right models, the right outcome and grouping variable, an
# ICC in a sensible range, and so on.
#
# WHAT THIS DOES NOT DO
#
# It cannot tell you whether your interpretation is any good. It does not read
# your predictions, your reconciliation, or your justification for a modeling
# decision, and those are the parts that carry the most weight. A clean report
# means your code is doing what the assignment asked. It does not mean you are
# finished.
#
# Nothing here is graded, and nothing is sent anywhere. Run it as often as you
# like.

# --- small helpers -----------------------------------------------------------

.ck_new <- function() list()

.ck_add <- function(res, label, status, msg = "") {
  res[[length(res) + 1]] <- list(label = label, status = status, msg = msg)
  res
}

# Every check is wrapped so that a broken object reports a failure rather than
# stopping the whole report.
.ck_try <- function(expr, fail_msg = "could not evaluate") {
  tryCatch(expr, error = function(e) structure(list(err = conditionMessage(e)),
                                               class = "ck_error"))
}
.ck_bad <- function(x) inherits(x, "ck_error")

# Find an object of a given class in the user's environment, whatever they
# happened to name it.
.ck_find <- function(env, predicate) {
  nms <- ls(envir = env)
  hits <- character(0)
  for (n in nms) {
    v <- .ck_try(get(n, envir = env))
    if (.ck_bad(v)) next
    ok <- .ck_try(isTRUE(predicate(v)))
    if (!.ck_bad(ok) && isTRUE(ok)) hits <- c(hits, n)
  }
  hits
}

.is_mermod <- function(x) inherits(x, c("lmerMod", "lmerModLmerTest", "glmerMod"))

# outcome and grouping factors from a fitted model, without needing lme4 loaded
.ck_outcome <- function(m) .ck_try(as.character(formula(m))[2])
.ck_groups  <- function(m) .ck_try(names(lme4::getME(m, "flist")))

.ck_icc <- function(m) {
  vc <- .ck_try(as.data.frame(lme4::VarCorr(m)))
  if (.ck_bad(vc)) return(NA_real_)
  grp <- vc$vcov[!is.na(vc$grp) & vc$grp != "Residual" & is.na(vc$var2)]
  res <- vc$vcov[vc$grp == "Residual"]
  if (!length(grp) || !length(res)) return(NA_real_)
  sum(grp) / (sum(grp) + res)
}

.ck_is_null_model <- function(m) {
  f <- .ck_try(formula(m))
  if (.ck_bad(f)) return(FALSE)
  rhs <- as.character(f)[3]
  # no fixed predictors: everything on the right is either 1 or a (…|…) term
  fixed <- gsub("\\([^)]*\\)", "", rhs)
  fixed <- gsub("[+~[:space:]1]", "", fixed)
  nchar(fixed) == 0
}

# --- report printing ---------------------------------------------------------

.ck_print <- function(res, module) {
  sym <- c(pass = "PASS", fail = "FAIL", warn = "CHECK", skip = "skip")
  bar <- strrep("-", 68)
  cat("\n", bar, "\n", sep = "")
  cat("  Self-check, Module ", module, "\n", sep = "")
  cat(bar, "\n\n", sep = "")
  for (r in res) {
    cat(sprintf("  [%-5s] %s\n", sym[[r$status]], r$label))
    if (nzchar(r$msg)) cat(sprintf("          %s\n", r$msg))
  }
  n_fail <- sum(vapply(res, function(r) r$status == "fail", logical(1)))
  n_warn <- sum(vapply(res, function(r) r$status == "warn", logical(1)))
  cat("\n", bar, "\n", sep = "")
  if (n_fail == 0 && n_warn == 0) {
    cat("  Mechanics look right.\n")
  } else {
    cat("  ", n_fail, " to fix, ", n_warn, " to look at.\n", sep = "")
  }
  cat("\n  This checks code only. Your interpretation, your predictions, and\n")
  cat("  your reasons for the choices you made are what get discussed at\n")
  cat("  checkout, and this cannot see any of them.\n")
  cat(bar, "\n\n", sep = "")
  invisible(NULL)
}

# --- module specifications ---------------------------------------------------
#
# Each module gets a function taking the student's environment and returning a
# list of check results. Add modules here as the term goes on.

.ck_mod3 <- function(env) {
  res <- .ck_new()

  # 1. is lme4 available at all
  if (!requireNamespace("lme4", quietly = TRUE)) {
    return(.ck_add(res, "lme4 installed", "fail",
                   "Run install.packages(\"lme4\") first."))
  }

  # 2. data
  dfs <- .ck_find(env, function(x) is.data.frame(x) && nrow(x) > 100)
  if (!length(dfs)) {
    res <- .ck_add(res, "Data loaded", "fail",
                   "No data frame found. Did the read_csv() or read_dta() line run?")
  } else {
    d <- get(dfs[1], envir = env)
    res <- .ck_add(res, "Data loaded", "pass",
                   sprintf("Found '%s' with %d rows and %d columns.",
                           dfs[1], nrow(d), ncol(d)))
    needed <- c("schoolid", "ses")
    missing <- needed[!needed %in% names(d)]
    if (length(missing)) {
      res <- .ck_add(res, "Expected columns present", "fail",
                     paste0("Missing: ", paste(missing, collapse = ", "),
                            ". Check you loaded the right file."))
    } else {
      res <- .ck_add(res, "Expected columns present", "pass")
    }
    if (!"readach" %in% names(d)) {
      res <- .ck_add(res, "Reading achievement variable", "warn",
                     paste0("No 'readach' column in this file. Columns are: ",
                            paste(utils::head(names(d), 12), collapse = ", "),
                            ". Ask Dr. Broda which file Part 1 expects."))
    }
  }

  # 3. models
  models <- .ck_find(env, .is_mermod)
  if (!length(models)) {
    res <- .ck_add(res, "Multilevel model fitted", "fail",
                   "No lmer() model found. Did that chunk run without error?")
    return(res)
  }
  res <- .ck_add(res, "Multilevel model fitted", "pass",
                 sprintf("Found %d: %s", length(models),
                         paste(models, collapse = ", ")))

  nulls <- Filter(function(n) isTRUE(.ck_is_null_model(get(n, envir = env))), models)
  if (!length(nulls)) {
    res <- .ck_add(res, "Null (unconditional) model", "fail",
                   "Every model has predictors. A null model is y ~ 1 + (1 | group).")
  } else {
    res <- .ck_add(res, "Null (unconditional) model", "pass",
                   sprintf("%s has no fixed predictors, as it should.", nulls[1]))
  }

  # 4. grouping variable
  bad_group <- character(0)
  for (n in models) {
    g <- .ck_groups(get(n, envir = env))
    if (!.ck_bad(g) && !any(grepl("school", g, ignore.case = TRUE))) bad_group <- c(bad_group, n)
  }
  if (length(bad_group)) {
    res <- .ck_add(res, "Clustered by school", "warn",
                   paste0("These are not grouped by schoolid: ",
                          paste(bad_group, collapse = ", "),
                          ". For this assignment students are nested in schools."))
  } else {
    res <- .ck_add(res, "Clustered by school", "pass")
  }

  # 5. two outcomes, per Parts 1 and 2
  outs <- unique(unlist(lapply(models, function(n) {
    o <- .ck_outcome(get(n, envir = env)); if (.ck_bad(o)) NA_character_ else o
  })))
  outs <- outs[!is.na(outs)]
  if (length(outs) >= 2) {
    res <- .ck_add(res, "Both parts attempted", "pass",
                   paste0("Outcomes modelled: ", paste(outs, collapse = ", ")))
  } else {
    res <- .ck_add(res, "Both parts attempted", "warn",
                   paste0("Only one outcome modelled (", paste(outs, collapse = ", "),
                          "). Part 2 asks for a second null model using ses."))
  }

  # 6. ICC sanity
  iccs <- vapply(nulls, function(n) .ck_icc(get(n, envir = env)), numeric(1))
  iccs <- iccs[!is.na(iccs)]
  if (!length(iccs)) {
    res <- .ck_add(res, "ICC computable", "warn",
                   "Could not read variance components. Check the model converged.")
  } else if (any(iccs <= 0 | iccs >= 1)) {
    res <- .ck_add(res, "ICC in a sensible range", "fail",
                   "An ICC came out outside 0 to 1, which means the arithmetic is off.")
  } else {
    res <- .ck_add(res, "ICC in a sensible range", "pass",
                   paste0("ICC(s): ", paste(sprintf("%.3f", iccs), collapse = ", "),
                          ". Whether that is large or small is yours to argue."))
  }

  # 7. estimator, since the course standardises on ML
  reml <- vapply(models, function(n) {
    v <- .ck_try(lme4::isREML(get(n, envir = env)))
    if (.ck_bad(v)) NA else isTRUE(v)
  }, logical(1))
  if (any(reml %in% TRUE)) {
    res <- .ck_add(res, "Fitted with REML = FALSE", "warn",
                   "At least one model used the REML default. This course uses ML, so add REML = FALSE.")
  } else {
    res <- .ck_add(res, "Fitted with REML = FALSE", "pass")
  }

  # 8. did they run the likelihood ratio test
  ran <- .ck_find(env, function(x) inherits(x, "anova") || inherits(x, "ranova"))
  if (!length(ran)) {
    res <- .ck_add(res, "Random effect tested", "warn",
                   "No saved ranova()/anova() result found. If you ran it without assigning it, that is fine.")
  } else {
    res <- .ck_add(res, "Random effect tested", "pass")
  }

  res
}

.ck_registry <- list("3" = .ck_mod3)

# --- the function students call ----------------------------------------------

check_module <- function(module, env = parent.frame()) {
  key <- as.character(module)
  if (is.null(.ck_registry[[key]])) {
    cat("\n  No self-check written for Module ", module, " yet.\n",
        "  Available: ", paste(names(.ck_registry), collapse = ", "), "\n\n", sep = "")
    return(invisible(NULL))
  }
  res <- .ck_registry[[key]](env)
  .ck_print(res, module)
  invisible(res)
}
