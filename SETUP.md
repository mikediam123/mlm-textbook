# Setup and Publishing Guide

This walks through getting the book rendering on your machine and published to GitHub Pages. Budget about half an hour the first time. After that, updating the site is two commands.

## Before you start

You need Quarto, which ships with recent versions of RStudio. Check by running `quarto --version` in the RStudio Terminal tab. If it is missing, install it from <https://quarto.org/docs/get-started/>.

You also need the R packages the chapters use:

```r
install.packages(c(
  "tidyverse", "haven", "psych", "lme4", "lmerTest",
  "performance", "see", "broom.mixed", "modelsummary", "ggeffects",
  "nlme", "influence.ME", "clubSandwich"
))
```

`see` is easy to miss because nothing loads it directly. `performance::check_model()` in Chapter 10 needs it, and fails unhelpfully without it.

## Step 1: Add the missing data files

Chapters 3 and 4 will render as-is, since `hsbmerged.csv` and `lq2002.csv` are already in the folder. Every other chapter uses a course dataset that is not, and the book will not render until you copy them in.

Copy these into the project folder, alongside the `.qmd` files:

- `egmerged.dta` (chapters 8a and 8b)
- `nsch_2018_topical.dta` (chapter 9)
- `productivity.dta` (chapter 10)

The others are already in place: `descriptive_gss.dta`, `food.csv`, `hsbmerged.csv`, `lq2002.csv`, `expanded_strs_no_miss.csv`, `projectSTAR.dta`, and `scotland.dta`.

Every dataset is the one used in the corresponding demonstration handout, so they should already exist alongside the videos.

If you would rather publish the first four chapters now and add the rest later, open each unfinished chapter and add this to the top of the file, just below the title:

```yaml
---
execute:
  eval: false
---
```

That displays the code without running it, so the book renders regardless.

## Step 2: Render locally and check the output

Open `MLM-Textbook.Rproj` to load the folder as an RStudio Project. Then use whichever of these you prefer:

- The **Render Book** button in the Build pane (top right)
- The **Terminal** tab, running `quarto render`
- The **Console** tab, running `quarto::quarto_render()` after `install.packages("quarto")`

One common stumble: `quarto render` is a shell command, so typing it into the R Console produces `unexpected symbol`. Use the Terminal tab for that version, or the `quarto::quarto_render()` function in the Console.

Expect this to surface errors the first time. The code in chapters 5 through 11 was written against your assignment variable names but has never been executed, so treat this pass as a proofreading exercise. The most likely problems are variable names that differ slightly from what the assignments document, factor levels that need different labels, and models that will not converge on the real data.

Work through one chapter at a time. Open a chapter, run the chunks interactively in RStudio, and fix what breaks before moving on. It is much easier than debugging a whole book render at once.

When it succeeds, open `docs/index.html` in a browser and click through the chapters.

## Step 3: The .nojekyll file (already automated)

GitHub Pages runs a tool called Jekyll by default, which ignores folders beginning with an underscore. Quarto generates several of those, so without an empty file named `.nojekyll` in `docs/`, your site publishes with no styling at all.

**This is handled for you.** `_postrender.R` runs after every render and creates the file if it is missing, so it survives any re-render that clears `docs/`. Nothing to do.

If you ever need to create it by hand, the Finder is the wrong tool: it hides files whose names begin with a dot (`Cmd+Shift+.` toggles visibility) and resists letting you create one. Use either the RStudio Console:

```r
file.create("docs/.nojekyll")
```

or the Terminal tab:

```bash
touch docs/.nojekyll
```

Confirm it exists with `list.files("docs", all.files = TRUE)` in R, or `ls -la docs/` in the Terminal. Ordinary `ls` will not show it.

One thing to watch when you get to step 4: `git add .` does include dotfiles, so `.nojekyll` will be committed normally. If the published site appears unstyled, the first thing to check is whether the file actually made it into the repository on github.com.

## Step 4: Create the GitHub repository

If you do not have a GitHub account, create one at <https://github.com>. A free account is all you need.

Create a new repository named something like `mlm-textbook`. Make it public, since GitHub Pages on free accounts requires it. Do not add a README, license, or .gitignore, since this folder already has what it needs.

### Confirm you are in the right folder first

This matters more than it sounds. Running `git init` in the wrong place, your home folder especially, creates a repository that tries to track everything beneath it.

The reliable way to avoid the problem is to not navigate at all. Open `MLM-Textbook.Rproj`, and the **Terminal** tab in RStudio starts in this folder already. Verify before doing anything:

```bash
pwd
ls _quarto.yml index.qmd && echo "correct folder"
```

`pwd` should end in `MLM Textbook Site`, and the second command should print `correct folder`. From the R Console the equivalent is `getwd()` and `file.exists("_quarto.yml")`.

If you ever do need to navigate by hand, note that the folder name contains spaces, so the path must be quoted:

```bash
cd "$HOME/Documents/MLM Class/MLM Textbook Site"
```

Without the quotes the command breaks at the first space. A shortcut that sidesteps the issue entirely: type `cd ` with a trailing space, then drag the folder from Finder into the Terminal window, which pastes a correctly escaped path.

### Then initialize and push

```bash
git init
git add .
git status
```

Stop and read the `git status` output before committing. You should see a few hundred recognizable files: the `.qmd` chapters, `docs/`, the data files. If you see thousands of files, or anything from outside this project, you are in the wrong folder. Run `rm -rf .git` to undo the initialization, which removes only git's tracking and leaves your files alone, then start again.

When it looks right:

```bash
git commit -m "Initial commit of MLM textbook"
git branch -M main
git remote add origin git@github.com:YOURUSERNAME/mlm-textbook.git
git push -u origin main
```

Replace `YOURUSERNAME` with your GitHub username. Note the SSH form of the address: `git@github.com:user/repo.git`, with a colon after the domain rather than a slash. See the authentication section below for why.

### Authentication: SSH keys with 1Password

GitHub stopped accepting account passwords for git operations years ago, so the first push needs either an SSH key or a personal access token. If you keep an SSH key in 1Password, that is the smoother path once configured.

**The mistake that wastes the most time** is having an SSH key set up correctly while the remote URL is still HTTPS. An HTTPS remote ignores SSH keys entirely and prompts for credentials instead. Check which you have:

```bash
git remote -v
```

If that shows `https://github.com/...`, switch it:

```bash
git remote set-url origin git@github.com:YOURUSERNAME/mlm-textbook.git
git remote -v
```

**If this machine already has an SSH key registered with GitHub**, which is common if you have used git here before, there is nothing further to configure. Confirm with `ssh -T git@github.com`, set the remote to the SSH form, and push. Skip the 1Password steps below.

**If you are prompted for a passphrase**, as in `Enter passphrase for key '/Users/you/.ssh/id_ed25519':`, the key is working and git simply needs to unlock it. Type the passphrase and press Enter. Nothing appears on screen as you type, which regularly convinces people the prompt has frozen. It has not.

To avoid being asked on every push, store the passphrase in the macOS Keychain once:

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

and add this to `~/.ssh/config` so the key is loaded automatically after a restart:

```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
```

If the passphrase is genuinely lost, generate a new key with `ssh-keygen -t ed25519` and add the new public key to GitHub. Nothing in the repository is affected.

**Configuring 1Password as the SSH agent**, if you do not already have a working key:

1. In 1Password, go to **Settings → Developer** and turn on **Use the SSH Agent**.
2. Create or edit `~/.ssh/config` (`mkdir -p ~/.ssh` then `open -e ~/.ssh/config`) and add:

   ```
   Host *
     IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
   ```

3. Add the **public** key to GitHub: your avatar → **Settings** → **SSH and GPG keys** → **New SSH key**. 1Password will usually offer to autofill this.

::: {.callout-warning}
The `Host *` line routes every SSH connection on this machine through 1Password's agent. If you already have a working key on disk, this will hide it and connections that used to succeed will start failing with `Permission denied (publickey)`. Either narrow the rule to `Host github.com`, or remove the block and use the existing key.
:::

**Test it before involving your repository:**

```bash
ssh -T git@github.com
```

1Password prompts for approval, then GitHub answers `Hi YOURUSERNAME! You've successfully authenticated, but GitHub does not provide shell access.` That second clause is expected and not an error. If you instead get `Permission denied (publickey)`, the key is not registered on GitHub or the agent is not running.

**If SSH proves fussy**, HTTPS with a personal access token also works: generate one under GitHub **Settings → Developer settings → Personal access tokens**, give it `repo` scope, and use it in place of a password at the prompt. Store it in 1Password, since it is shown only once. This is a fine fallback, though you will re-enter it more often than SSH asks for approval.

### After the first push: use the Git pane

Once the repository exists, close and reopen the project in RStudio. A **Git** tab appears in the top-right pane, listing changed files with checkboxes. From then on you can stage, commit, and push by clicking rather than typing, and the folder question never comes up again because the pane only ever acts on this project.

## Step 5: Turn on GitHub Pages

In your repository on github.com, go to **Settings**, then **Pages** in the left sidebar.

Under "Build and deployment," set Source to **Deploy from a branch**. Set the branch to **main** and the folder to **/docs**. Click Save.

Wait a minute or two, then reload the page. GitHub will show you the URL, which will look like:

```
https://YOURUSERNAME.github.io/mlm-textbook/
```

That is the link to give students, and the one to replace your old bookdown.org link with.

## Step 6: Update the repo URL in the config

Open `_quarto.yml` and replace `YOURUSERNAME` in the `repo-url` line with your actual username. Re-render and push so the links in the site header work.

## Updating the site later

Once set up, the cycle is short:

```bash
quarto render
git add .
git commit -m "Describe what changed"
git push
```

The live site updates within a minute or two. Note that you must commit the `docs/` folder, which is why it is deliberately not in `.gitignore`.

## Notes and gotchas

**Keep this folder out of Google Drive and Dropbox.** Sync services and git both want to manage the `.git` directory, and they corrupt each other. Keeping the project in a plain local folder like `~/Documents` avoids a class of confusing failures. Your original bookdown folder can stay where it is as an archive.

**The freeze setting.** `_quarto.yml` sets `freeze: auto`, which caches chapter results so that only chapters you have edited get re-run. This makes rendering much faster. If results seem stale, delete the `_freeze/` folder and render again.

**If the site appears unstyled.** This is almost always the missing `.nojekyll` file from step 3.

**If images show as broken icons on the published site but look fine locally.** The figure folders are not in the repository. Quarto writes plots to `docs/<chapter>_files/`, and a `.gitignore` rule like `*_files/` matches those as well as the knitr intermediates it was meant for. The rule needs a leading slash (`/*_files/`) so it applies only at the project root.

Check with:

```bash
git check-ignore -v docs/01-getting-started_files
```

Silence means the folder will be committed. Any output names the offending rule and the line it sits on. After fixing the rule, `git add .` will pick the figures up.

**Check for third-party scripts before publishing.** Pandoc's MathJax template historically injected a reference to `polyfill.io`, a CDN that was sold in 2024 and briefly served malware before the domain was suspended. This project uses KaTeX instead, which avoids it. After any render, it is worth confirming that nothing external crept back in:

```bash
grep -rl "polyfill" docs/ || echo "clean"
```

More generally, anything the rendered pages load from a domain you do not control is a dependency your students inherit. Keeping that list short is worth the small effort.

**If a chapter fails to render.** Quarto reports the chapter and line. Open that file, run the chunk in RStudio, and fix it there.

**If a chunk is supposed to fail.** Some chunks demonstrate what goes wrong, and knitr stops the whole render when R throws an error. Add `error: true` to the chunk options and the error is displayed as part of the book while rendering continues:

````
```{r}
#| error: true

# code that is meant to break
```
````

Chapter 6 uses this for the over-specified random effects model. Chapter 10's diagnostic code is the next most likely place to need it, since `influence.ME` and `clubSandwich` can be slow or fussy on large datasets.

## On the old bookdown project

Your original project used bookdown, whose free hosting at bookdown.org went read-only on January 31, 2026. The bookdown R package itself is still maintained, so the old project will still build locally. This Quarto version is the forward-looking replacement, and it has the added benefit of matching the format students now use for their assignments.
