# make_student_files.R -------------------------------------------------------
#
# Generates companion files for students to use while watching the
# demonstration videos. Run from the project folder after any chapter edit:
#
#   Rscript make_student_files.R      (Terminal)
#   source("make_student_files.R")    (RStudio Console)
#
# Produces three things in student_files/ , plus a zip for Canvas:
#
#   code/<chapter>-code.R
#       Every line of R from the chapter, prose stripped, section headers kept
#       as comment banners. The reference copy, and the catch-up path for
#       anyone who falls behind during a video.
#
#   followalong/<chapter>-followalong.qmd
#       A Quarto document students fill in as they watch. Setup and data
#       loading are done for them; the model-fitting calls are replaced with
#       YOUR TURN prompts so they type the syntax themselves. The book's
#       version sits in an HTML comment directly below, so nobody gets
#       stranded, and it does not appear in the rendered output.
#
#   followalong/<chapter>-followalong.R
#       Same idea as a plain R script, for students who would rather not
#       render anything.
#
# All three are generated from the .qmd chapters, so they cannot drift out of
# sync. Regenerate rather than editing them by hand.
#
# REVIEW A FEW FOLLOW-ALONG FILES BEFORE POSTING. The rule for what to blank is
# a heuristic (any assignment whose right-hand side calls lmer/glmer/lme/rlmer)
# and it will occasionally blank something you wanted left alone.

dir.create("student_files", showWarnings = FALSE)
dir.create("student_files/code", showWarnings = FALSE)
dir.create("student_files/followalong", showWarnings = FALSE)

# Match 01-, 02-, and also 08a-, 08b-. The earlier version of this script used
# "^[0-9]{2}-" and silently skipped both growth chapters.
chapters <- sort(list.files(".", pattern = "^[0-9]{2}[a-z]?-.*\\.qmd$"))

# --- helpers ---------------------------------------------------------------

banner <- function(text, level) {
  if (level == 1) {
    c("", strrep("#", 74), paste("##", toupper(text)), strrep("#", 74), "")
  } else if (level == 2) {
    bar <- strrep("-", max(4, 70 - nchar(text)))
    c("", paste("#", text, bar), "")
  } else {
    c("", paste("##", text), "")
  }
}

starts_model_call <- function(line) {
  # Longest names first: "lmer" must be tried before "lme" and "lm", or
  # lmer(...) would match the shorter alternative and mis-mark the run.
  grepl("^\\s*[\\w.]+\\s*(<-|=)\\s*(lme4::|lmerTest::|nlme::|robustlmm::)?(lmer|glmer|rlmer|glm|lme|lm)\\s*\\(",
        line, perl = TRUE)
}

paren_balance <- function(line) {
  lengths(regmatches(line, gregexpr("\\(", line))) -
    lengths(regmatches(line, gregexpr("\\)", line)))
}

# Parse a .qmd into an ordered list of blocks: headers and code chunks.
parse_chapter <- function(path) {
  lines <- readLines(path, warn = FALSE)
  blocks <- list()
  in_chunk <- FALSE
  in_yaml  <- FALSE
  opts <- character(0)
  body <- character(0)

  for (i in seq_along(lines)) {
    ln <- lines[i]

    # skip a YAML block if the file has one
    if (i == 1 && grepl("^---\\s*$", ln)) { in_yaml <- TRUE; next }
    if (in_yaml) { if (grepl("^---\\s*$", ln)) in_yaml <- FALSE; next }

    if (!in_chunk && grepl("^```\\{r", ln)) {
      in_chunk <- TRUE; opts <- character(0); body <- character(0); next
    }
    if (in_chunk && grepl("^```\\s*$", ln)) {
      blocks[[length(blocks) + 1]] <- list(
        type = "chunk",
        eval = !any(grepl("eval:\\s*false", opts)),
        label = {
          lb <- grep("#\\|\\s*label:", opts, value = TRUE)
          if (length(lb)) sub(".*label:\\s*", "", lb[1]) else ""
        },
        code = body
      )
      in_chunk <- FALSE; next
    }
    if (in_chunk) {
      if (grepl("^#\\|", ln)) opts <- c(opts, ln) else body <- c(body, ln)
      next
    }
    if (grepl("^#{1,3} ", ln)) {
      blocks[[length(blocks) + 1]] <- list(
        type = "header",
        level = nchar(sub("^(#+) .*", "\\1", ln)),
        text = sub("^#+ ", "", ln)
      )
    }
  }
  blocks
}

# Split a chunk's code into runs, marking which lines belong to a model call.
mark_model_runs <- function(code) {
  flags <- rep(FALSE, length(code))
  i <- 1
  while (i <= length(code)) {
    if (starts_model_call(code[i])) {
      bal <- paren_balance(code[i]); j <- i
      while (bal > 0 && j < length(code)) { j <- j + 1; bal <- bal + paren_balance(code[j]) }
      flags[i:j] <- TRUE
      i <- j + 1
    } else i <- i + 1
  }
  flags
}

# --- builders --------------------------------------------------------------

build_code_R <- function(blocks) {
  out <- character(0)
  for (b in blocks) {
    if (b$type == "header") {
      out <- c(out, banner(b$text, b$level))
    } else {
      if (!length(b$code)) next
      if (nzchar(b$label)) out <- c(out, paste0("# [", b$label, "]"))
      if (b$eval) out <- c(out, b$code, "")
      else out <- c(out, "# (not run in the book - shown for reference)",
                    paste("#", b$code), "")
    }
  }
  out[!(out == "" & c(FALSE, head(out, -1) == ""))]
}

build_followalong_R <- function(blocks) {
  out <- character(0)
  for (b in blocks) {
    if (b$type == "header") { out <- c(out, banner(b$text, b$level)); next }
    if (!length(b$code)) next
    if (!b$eval) {
      out <- c(out, "# (not run in the book - shown for reference)",
               paste("#", b$code), ""); next
    }
    flags <- mark_model_runs(b$code)
    i <- 1
    while (i <= length(b$code)) {
      if (flags[i]) {
        j <- i; while (j < length(flags) && flags[j + 1]) j <- j + 1
        out <- c(out,
                 "# ---- YOUR TURN ---------------------------------------------",
                 "# Type the model here while the video walks through it.",
                 "",
                 "",
                 "# The book's version, for checking after you have tried:",
                 paste("#", b$code[i:j]),
                 "# ------------------------------------------------------------",
                 "")
        i <- j + 1
      } else {
        out <- c(out, b$code[i]); i <- i + 1
      }
    }
    out <- c(out, "")
  }
  out[!(out == "" & c(FALSE, head(out, -1) == ""))]
}

build_followalong_qmd <- function(blocks, title) {
  out <- c(
    "---",
    paste0('title: "', title, '"'),
    'subtitle: "Follow-along worksheet"',
    'author: "Your name here"',
    "date: today",
    "format:",
    "  html:",
    "    embed-resources: true",
    "    toc: true",
    "execute:",
    "  warning: true",
    "---",
    "",
    "> Fill this in as you watch the demonstration video. Sections marked",
    "> **Your turn** are for you to type. The book's version is in a hidden",
    "> comment just below each one, so check yourself after you have tried.",
    ">",
    "> This document will not render until every **Your turn** chunk is filled",
    "> in, because later code depends on the models you create. That is",
    "> deliberate. If rendering fails, look for the first empty chunk rather",
    "> than assuming something is broken.",
    ""
  )

  for (b in blocks) {
    if (b$type == "header") {
      out <- c(out, "", paste(strrep("#", min(b$level + 1, 4)), b$text), "")
      next
    }
    if (!length(b$code)) next
    if (!b$eval) {
      out <- c(out, "```{r}", "#| eval: false", "", b$code, "```", "")
      next
    }
    flags <- mark_model_runs(b$code)
    i <- 1
    while (i <= length(b$code)) {
      if (flags[i]) {
        j <- i; while (j < length(flags) && flags[j + 1]) j <- j + 1
        out <- c(out,
                 "::: {.callout-note}",
                 "## Your turn",
                 "Type the model in the chunk below.",
                 ":::",
                 "",
                 "```{r}",
                 "# YOUR CODE HERE",
                 "",
                 "```",
                 "",
                 "<!-- The book's version, for checking after you have tried:",
                 b$code[i:j],
                 "-->",
                 "")
        i <- j + 1
      } else {
        # collect a run of non-model lines into one chunk
        j <- i; while (j < length(flags) && !flags[j + 1]) j <- j + 1
        run <- b$code[i:j]
        # trim blank lines from the ends so chunks do not open on an empty line
        while (length(run) && !nzchar(trimws(run[1]))) run <- run[-1]
        while (length(run) && !nzchar(trimws(run[length(run)]))) run <- run[-length(run)]
        if (length(run)) {
          out <- c(out, "```{r}", run, "```", "")
        }
        i <- j + 1
      }
    }
  }
  out
}

# --- run -------------------------------------------------------------------

summary_tbl <- data.frame(chapter = character(0), code_lines = integer(0),
                          models_blanked = integer(0), stringsAsFactors = FALSE)

for (qmd in chapters) {
  stem   <- sub("\\.qmd$", "", qmd)
  blocks <- parse_chapter(qmd)
  chunks <- Filter(function(b) b$type == "chunk", blocks)

  # Skip prose-only chapters, such as the Module 2 reading.
  if (!length(chunks)) {
    message("Skipping ", qmd, " (no code chunks)")
    next
  }

  title <- {
    l <- readLines(qmd, warn = FALSE)
    h <- grep("^# ", l, value = TRUE)
    if (length(h)) sub("^#\\s*", "", h[1]) else stem
  }

  hdr <- c(
    paste0("# ", title),
    "# EDUS 664 - Multilevel Modeling",
    "#",
    "# Keep this file in the same folder as the data file named at the top of",
    "# the chapter, or the read_ lines below will not find it.",
    paste0("# Generated from ", qmd, " on ", Sys.Date(), " - do not edit by hand."),
    ""
  )

  code_R <- build_code_R(blocks)
  writeLines(c(hdr, "# Reference version: complete code from the chapter.", "", code_R),
             file.path("student_files/code", paste0(stem, "-code.R")))

  fa_R <- build_followalong_R(blocks)
  writeLines(c(hdr, "# FOLLOW-ALONG version: type the marked models yourself.", "", fa_R),
             file.path("student_files/followalong", paste0(stem, "-followalong.R")))

  fa_qmd <- build_followalong_qmd(blocks, title)
  writeLines(fa_qmd,
             file.path("student_files/followalong", paste0(stem, "-followalong.qmd")))

  n_blank <- sum(vapply(chunks, function(b) sum(rle(mark_model_runs(b$code))$values), integer(1)))

  summary_tbl <- rbind(summary_tbl, data.frame(
    chapter = stem, code_lines = length(code_R), models_blanked = n_blank,
    stringsAsFactors = FALSE))
}

print(summary_tbl, row.names = FALSE)

old <- setwd("student_files")
utils::zip("../student_files.zip", files = list.files(".", recursive = TRUE))
setwd(old)

message("\nWrote student_files/ and student_files.zip")
message("Review a few follow-along files before posting: the YOUR TURN rule is a heuristic.")
