# archive_rpubs.R ------------------------------------------------------------
# Downloads all 13 MLM demonstrations from RPubs and, where possible, extracts
# the original .Rmd source that RStudio embedded in each published page.
#
# Run this from the project folder. Output lands in rpubs_archive/.
#
# Why now: Posit has announced that RPubs retires in June 2027, with existing
# documents readable through December 31, 2031. Nothing disappears tomorrow,
# but there is no reason to leave the only copy of six years of teaching
# material on a service with an end date.

library(tools)

dir.create("rpubs_archive", showWarnings = FALSE)
dir.create("rpubs_archive/html", showWarnings = FALSE)
dir.create("rpubs_archive/rmd", showWarnings = FALSE)

# slug -> S3 document id, read off the RPubs profile page
docs <- c(
  "module1mlm"             = "652407_dcc2854618be44b9b0bc3e4535e51c01",
  "module1demomlm"         = "652522_4f684b187e194bac91c2d50e6cdffa49",
  "module2demomlm"         = "652808_8590259ef71741988f22c5d6a44af8b3",
  "module3demomlm"         = "655376_2f0a9fbb863747d3b0758ee76344b299",
  "module4demomlm"         = "658243_faea5082fa9641bd8323bc3186d93140",
  "module5contentreviewmlm"= "661731_38942d4f902e4bef99e110781f7030c1",
  "module5demomlm"         = "661929_ae25f1243a764a339257a6d1c69ca7e8",
  "week7demomlm"           = "668697_3774d4a734644bb99b12d1c24276d3f2",
  "module8part1demomlm"    = "671445_79ff92bbefbf4aef8ebf47f15e0c83e4",
  "module8part2demomlm"    = "675196_ceba78b1b0ab449ca8578cab8af6c418",
  "module9demomlm"         = "678923_6bc4c0cceae047e2bc6cd04d6cc90f99",
  "module10demomlm"        = "681754_c777f1686ba94de2a76a841a3dc497ca",
  "module11demomlm"        = "685784_59c5a09ba71e469994e27edbf6e5eff6"
)

base <- "https://rstudio-pubs-static.s3.amazonaws.com/"

extract_rmd <- function(html_text) {
  # RStudio embeds the source as base64. Two common shapes:
  #   <div id="rmd-source-code">BASE64</div>          (html_document)
  #   a bare base64 blob near the end of the body      (html_notebook)
  m <- regmatches(
    html_text,
    regexpr('(?<=id="rmd-source-code">)[A-Za-z0-9+/=\\s]+(?=</div>)',
            html_text, perl = TRUE)
  )
  if (length(m) == 0) {
    # fall back: longest base64-looking run in the document
    cand <- regmatches(html_text,
                       gregexpr("[A-Za-z0-9+/=]{500,}", html_text, perl = TRUE))[[1]]
    if (length(cand) == 0) return(NULL)
    m <- cand[which.max(nchar(cand))]
  }
  out <- try(rawToChar(base64enc::base64decode(gsub("\\s", "", m))), silent = TRUE)
  if (inherits(out, "try-error")) return(NULL)
  # sanity check: does it look like an Rmd?
  if (!grepl("```\\{r", out) && !grepl("^---", out)) return(NULL)
  out
}

if (!requireNamespace("base64enc", quietly = TRUE)) {
  install.packages("base64enc")
}

results <- data.frame(slug = names(docs), html = FALSE, rmd = FALSE,
                      stringsAsFactors = FALSE)

for (i in seq_along(docs)) {
  slug <- names(docs)[i]
  url  <- paste0(base, docs[i], ".html")
  html_path <- file.path("rpubs_archive/html", paste0(slug, ".html"))

  message("Downloading ", slug, " ...")
  ok <- try(download.file(url, html_path, quiet = TRUE, mode = "wb"), silent = TRUE)

  if (inherits(ok, "try-error")) {
    warning("Could not download ", slug)
    next
  }
  results$html[i] <- TRUE

  txt <- paste(readLines(html_path, warn = FALSE), collapse = "\n")
  rmd <- extract_rmd(txt)

  if (!is.null(rmd)) {
    writeLines(rmd, file.path("rpubs_archive/rmd", paste0(slug, ".Rmd")))
    results$rmd[i] <- TRUE
  } else {
    message("  (no embedded source found; HTML saved)")
  }
}

print(results)
message("\nDone. HTML in rpubs_archive/html, recovered source in rpubs_archive/rmd")
message("Any file without recovered source can still be read from the HTML, or ",
        "opened on RPubs and downloaded with the 'Download Rmd' toolbar button.")
