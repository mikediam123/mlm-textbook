# make_student_files.R -------------------------------------------------------
#
# Generates two companion files per chapter for students to use while watching
# the demonstration videos. Run from the project folder after any chapter edit.
#
#   student_files/code/chapter-NN-code.R
#       Every line of R from the chapter, with the section headers preserved as
#       comment banners and the prose stripped out. This is the reference copy,
#       and the one to fall back on when someone gets lost.
#
#   student_files/followalong/chapter-NN-followalong.R
#       The same file, but with the model-fitting calls commented out and
#       marked YOUR TURN. Students type those lines themselves while watching.
#       The answer sits directly below, commented, so nobody gets stranded.
#
# Both are generated from the .qmd files, so they cannot drift out of sync.
# Regenerate rather than editing them by hand.
#
# REVIEW THE FOLLOW-ALONG FILES BEFORE POSTING. The rule for what to blank is a
# heuristic (any assignment whose right-hand side calls lmer/glmer/lme), and it
# will occasionally blank something you wanted left alone, or miss something you
# wanted blanked.

dir.create("student_files", showWarnings = FALSE)
dir.create("student_files/code", showWarnings = FALSE)
dir.create("student_files/followalong", showWarnings = FALSE)

chapters <- sort(list.files(".", pattern = "^[0-9]{2}-.*\\.qmd$"))

banner <- function(text, level) {
  bar <- strrep("-", max(4, 72 - nchar(text) - 4))
  if (level == 1) {
    c("", strrep("#", 74), paste("##", toupper(text)), strrep("#", 74), "")
  } else if (level == 2) {
    c("", paste("#", text, bar), "")
  } else {
    c("", paste("##", text), "")
  }
}

# Does this line start an assignment whose value comes from a model call?
starts_model_call <- function(line) {
  grepl("^\\s*[\\w.]+\\s*(<-|=)\\s*(lme4::|lmerTest::|nlme::)?(lmer|glmer|lme)\\s*\\(",
        line, perl = TRUE)
}

paren_balance <- function(line) {
  # crude but adequate: ignores parens inside strings, which we do not have here
  lengths(regmatches(line, gregexpr("\\(", line))) -
    lengths(regmatches(line, gregexpr("\\)", line)))
}

extract <- function(path) {
  lines <- readLines(path, warn = FALSE)
  out <- character(0)
  in_chunk <- FALSE
  chunk_opts <- character(0)
  chunk_body <- character(0)

  flush_chunk <- function() {
    if (!length(chunk_body)) return(invisible(NULL))
    is_eval_false <- any(grepl("eval:\\s*false", chunk_opts))
    body <- chunk_body
    if (is_eval_false) {
      out <<- c(out, "# (not run in the book - shown for reference)",
                paste("#", body), "")
    } else {
      out <<- c(out, body, "")
    }
    invisible(NULL)
  }

  for (ln in lines) {
    if (!in_chunk && grepl("^```\\{r", ln)) {
      in_chunk <- TRUE; chunk_opts <- character(0); chunk_body <- character(0)
      next
    }
    if (in_chunk && grepl("^```\\s*$", ln)) {
      flush_chunk(); in_chunk <- FALSE; next
    }
    if (in_chunk) {
      if (grepl("^#\\|", ln)) {
        chunk_opts <- c(chunk_opts, ln)
        if (grepl("#\\|\\s*label:", ln)) {
          lbl <- sub(".*label:\\s*", "", ln)
          chunk_body <- c(chunk_body, paste0("# [", lbl, "]"))
        }
      } else {
        chunk_body <- c(chunk_body, ln)
      }
      next
    }
    # outside chunks: keep headers only
    if (grepl("^#{1,3} ", ln)) {
      lvl <- nchar(sub("^(#+) .*", "\\1", ln))
      out <- c(out, banner(sub("^#+ ", "", ln), lvl))
    }
  }
  # collapse runs of blank lines
  out <- out[!(out == "" & c(FALSE, head(out, -1) == ""))]
  out
}

# Comment out model calls, leaving the answer visible directly below.
blank_models <- function(code) {
  out <- character(0)
  i <- 1
  while (i <= length(code)) {
    if (starts_model_call(code[i])) {
      bal <- paren_balance(code[i]); j <- i
      while (bal > 0 && j < length(code)) { j <- j + 1; bal <- bal + paren_balance(code[j]) }
      out <- c(out,
               "# ---- YOUR TURN ----------------------------------------------",
               "# Type the model here while the video walks through it.",
               "# The version from the book is commented out below; uncomment",
               "# it only after you have written your own and compared.",
               "",
               paste("#", code[i:j]),
               "# -------------------------------------------------------------",
               "")
      i <- j + 1
    } else {
      out <- c(out, code[i]); i <- i + 1
    }
  }
  out
}

header_for <- function(qmd, kind) {
  title <- sub("^#\\s*", "", grep("^# ", readLines(qmd, warn = FALSE), value = TRUE)[1])
  c(paste0("# ", title),
    "# EDUS 664 - Multilevel Modeling",
    if (kind == "followalong")
      "# FOLLOW-ALONG version. Type the marked models yourself."
    else
      "# Reference version. Complete code from the chapter.",
    "#",
    "# Keep this file in the same folder as the data file named at the",
    "# top of the chapter, or the read_ lines below will not find it.",
    paste0("# Generated from ", qmd, " on ", Sys.Date(), " - do not edit by hand."),
    "")
}

summary_tbl <- data.frame(chapter = chapters, code_lines = NA_integer_,
                          models_blanked = NA_integer_)

for (k in seq_along(chapters)) {
  qmd <- chapters[k]
  stem <- sub("\\.qmd$", "", qmd)
  code <- extract(qmd)

  writeLines(c(header_for(qmd, "code"), code),
             file.path("student_files/code", paste0(stem, "-code.R")))

  fa <- blank_models(code)
  writeLines(c(header_for(qmd, "followalong"), fa),
             file.path("student_files/followalong", paste0(stem, "-followalong.R")))

  summary_tbl$code_lines[k] <- length(code)
  summary_tbl$models_blanked[k] <- sum(vapply(code, starts_model_call, logical(1)))
}

print(summary_tbl, row.names = FALSE)

# Zip for posting to Canvas
old <- setwd("student_files")
utils::zip("../student_files.zip", files = list.files(".", recursive = TRUE))
setwd(old)

message("\nWrote student_files/ and student_files.zip")
message("Review a few follow-along files before posting: the YOUR TURN rule is a heuristic.")
