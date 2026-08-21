#!/usr/bin/env bash
# make_reading_pdf.sh ---------------------------------------------------------
# Rebuilds the Module 2 reading as a standalone PDF for Canvas.
#
# Run from the project folder:
#   bash make_reading_pdf.sh
#
# The PDF is generated from the same .qmd file as the website chapter, so the
# two cannot drift apart. Re-run this after editing 02-reading-regression.qmd.
#
# Requires pandoc and a LaTeX installation with xelatex. On macOS, the smallest
# option is BasicTeX (`brew install --cask basictex`), or use the "Render to
# PDF" route described at the bottom of this file if you would rather not
# install LaTeX.

set -e

SRC="02-reading-regression.qmd"
OUT="Module 2 Reading - Regression and Where It Runs Out.pdf"
DEST="../Readings"

command -v pandoc >/dev/null || { echo "pandoc not found"; exit 1; }
command -v xelatex >/dev/null || { echo "xelatex not found; see notes at the bottom of this script"; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# Drop the H1 (it becomes the PDF title block instead of a section heading)
tail -n +2 "$SRC" > "$TMP/body.md"

cat > "$TMP/header.tex" <<'EOF'
\usepackage{xcolor}
\definecolor{coursetal}{HTML}{1A7A6E}
\definecolor{darkink}{HTML}{1A2E2B}
\definecolor{rulegray}{HTML}{C9D6D3}

\usepackage{titlesec}
\titleformat{\section}{\Large\bfseries\color{coursetal}}{\thesection}{0.6em}{}
\titlespacing*{\section}{0pt}{1.6em}{0.5em}
\titleformat{\subsection}{\large\bfseries\color{darkink}}{\thesubsection}{0.6em}{}
\titlespacing*{\subsection}{0pt}{1.2em}{0.35em}

\usepackage{fancyhdr}
\pagestyle{fancy}
\fancyhf{}
\renewcommand{\headrulewidth}{0.4pt}
\renewcommand{\headrule}{\hbox to\headwidth{\color{rulegray}\leaders\hrule height \headrulewidth\hfill}}
\fancyhead[L]{\small\color{gray!70}EDUS 664 \textperiodcentered\ Multilevel Modeling}
\fancyhead[R]{\small\color{gray!70}Module 2 Reading}
\fancyfoot[C]{\small\color{gray!70}\thepage}

\usepackage{setspace}
\setstretch{1.12}
\setlength{\parskip}{0.55em}
\setlength{\parindent}{0pt}

\usepackage{microtype}

\usepackage{titling}
\pretitle{\begin{flushleft}\huge\bfseries\color{darkink}}
\posttitle{\end{flushleft}\vspace{-0.3em}{\color{coursetal}\rule{\textwidth}{2pt}}\vspace{0.4em}}
\preauthor{\begin{flushleft}\large\color{gray!60}}
\postauthor{\end{flushleft}}
\predate{\begin{flushleft}\small\color{gray!60}}
\postdate{\end{flushleft}}
EOF

mkdir -p "$DEST"

pandoc "$TMP/body.md" \
  -o "$DEST/$OUT" \
  --pdf-engine=xelatex \
  --include-in-header="$TMP/header.tex" \
  --shift-heading-level-by=-1 \
  -V mainfont="Georgia" \
  -V fontsize=11pt \
  -V geometry:"letterpaper,margin=1.1in,top=1.15in,bottom=1.1in" \
  -V linkcolor=coursetal \
  -V urlcolor=coursetal \
  -V title="Regression and Where It Runs Out" \
  -V author="EDUS 664: Multilevel Modeling \\\\ Dr. Michael Broda \\textperiodcentered\\ Virginia Commonwealth University" \
  -V date="Module 2 Reading"

echo "Wrote $DEST/$OUT"

# ---------------------------------------------------------------------------
# Font note
#
# The body font is TeX Gyre Pagella, an open Palatino that ships with most
# LaTeX distributions. If you would rather match the Georgia used elsewhere in
# the course materials, change mainfont to "Georgia" — it is installed on macOS
# and xelatex can use it directly.
#
# No LaTeX installed?
#
# Quarto can render a single file to PDF on its own:
#     quarto render 02-reading-regression.qmd --to pdf
# That still needs LaTeX, but `quarto install tinytex` will fetch a minimal one
# for you. Alternatively, render to .docx and export a PDF from Word:
#     quarto render 02-reading-regression.qmd --to docx
# ---------------------------------------------------------------------------
