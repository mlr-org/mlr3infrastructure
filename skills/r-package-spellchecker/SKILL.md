---
name: r-package-spellchecker
description: >
  Spellcheck an R package with cspell, fix genuine typos in source files,
  and add legitimate domain words to .cspell/project-words.txt.
  Use when the user asks to spellcheck the package, run cspell, fix typos,
  or clean up the project dictionary.
---

# R package spellchecker

Spellcheck the package with cspell, fix genuine typos, and add legitimate words to the shared project dictionary.

The cspell configuration lives in `cspell.json` at the package root.
It checks markdown, plaintext, and `.qmd` files, plus comments (including roxygen) in R files.
The shared dictionary is `.cspell/project-words.txt`.

## Workflow

1. **Run cspell** from the package root (the config is auto-detected):

   ```sh
   # Issues with file/line locations for context
   npx --yes cspell --no-progress --relative .

   # Deduplicated list of unknown words
   npx --yes cspell --no-progress --words-only --unique . | sort -fu
   ```

2. **Triage each unknown word** using its source context (read the surrounding line in the reporting file when unsure):
   - **Genuine typo** → fix it in the source file. Never add a typo to the dictionary.
   - **Legitimate word** → append it to `.cspell/project-words.txt`.
     Examples: package, class, and function names (`bbotk`, `Classif`, `clbk`),
     math and optimization jargon (`codomain`, `BOBYQA`),
     author surnames from the bibliography (`Bischl`, `Birattari`),
     and established abbreviations (`evals`).
   - When a word is ambiguous, prefer fixing over adding, and mention the judgment call in the final report.

3. **Apply the fixes**, respecting these rules:
   - The language is en-US. British spellings are typos to fix, not words to add.
   - Never edit generated files. Fix typos in `README.Rmd` and regenerate with `Rscript -e "devtools::build_readme()"`, never edit `README.md` directly. `man/` and `*.Rd` are already ignored by the config.
   - After fixing typos in roxygen comments, run `Rscript -e "devtools::document()"`.
   - Keep `.cspell/project-words.txt` one word per line, sorted alphabetically case-insensitively, below the existing header comments.

4. **Verify**: re-run cspell until it reports no unknown words and exits 0.

5. **Report**: summarize the typos fixed (file: old → new) and the words added to the dictionary.
