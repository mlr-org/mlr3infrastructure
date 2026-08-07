# R Package Development – General and mlr3 Ecosystem

## Package

Config and agent/rules files for R package development, located in `package/`.

- **.editorconfig** – Basic editor config. We also have autoformatters and IDE-specific settings that match.
- **.gitignore** – Gitignore rules for R packages.
- **.Rbuildignore** – Files excluded from the R package tarball.
- **.lintr** – Linting configuration for R code.
- **air.toml** – Configuration for the [air](https://github.com/posit-dev/air) R formatter.
- **cspell.json** – Spell-checking configuration.
- **.cspell/project-words.txt** – Project-specific dictionary for cspell.
- **.clang-format** – Clang-format configuration (for packages with C/C++ code).
- **.Rprofile** – Setup for a standard R console. Not shipped in project dirs, as people have different preferences (some of us use "radian"). Best use: copy or symlink to your HOME directory.
- **.vscode/settings.json** – VS Code workspace settings.
- **.vscode/tasks.json** – VS Code build tasks (for packages with C/C++ code).
- **AGENTS.md** – Development guidelines for AI coding agents (key commands, coding standards, testing, documentation, NEWS.md, writing). Symlinked as `CLAUDE.md`.
- **extra-rules/mlr3.md** – Additional rules specific to the mlr3 ecosystem.
- **Package installations and updates** – Use [pak](https://pak.r-lib.org/). The `.Rprofile` above also has a small helper to install binaries from Posit.

### Setting up a new package

To apply the package config files to a new or existing R package, use the `/r-package-setup` skill in Claude Code.
It copies the relevant files from `package/` into the target directory, creates the `CLAUDE.md` symlink, and optionally includes mlr3-specific rules and C/C++ tooling.

## Workflows

- **r-cmd-check** – Runs R CMD check via the `rcmdcheck` package on the latest and devel R version.
Workflow by [r-lib/actions](https://github.com/r-lib/actions).
- **dev-cmd-check** – Checks a package against the dev version of one of its dependencies.
For example, the `mlr3` repository uses this workflow to check whether `mlr3` works with the dev version of `mlr3misc`.
- **revdep-check** – Checks the reverse dependencies of a package against its own dev version.
For example, the `mlr3misc` repository uses this workflow to check whether `mlr3` still works with the dev version of `mlr3misc`.
- **pkgdown** – Builds a `pkgdown` site and pushes it to gh pages.
Workflow by [r-lib/actions](https://github.com/r-lib/actions).
- **no-suggest-cmd-check** – Runs R CMD check via the `rcmdcheck` package on the latest and devel R version without suggested packages.
Workflow by [r-lib/actions](https://github.com/r-lib/actions).
- **quarto-netlify-preview** – Deploys previews of rendered quarto sites to [Netlify](https://www.netlify.com/).

When triggering the workflows manually, the "tmate debugging" flag can be checked which will allow you to directly interact with the host system on which the actual scripts (actions) will run.
To continue the action, run `touch continue`.
A more detailed description of this workflow can be found [here](https://github.com/mxschmitt/action-tmate).
Tmate can also be used to debug problems on other machines than ones own, for more information see [this article](https://yihui.org/en/2022/12/gha-debug/).

## Skills

Claude Code skills for working with mlr3 packages.

- **authoring** – Guides Quarto document authoring and R Markdown migration to Quarto.
- **cran-extrachecks** – Checks for common CRAN requirements not caught by `devtools::check()`.
- **critical-code-reviewer** – Conducts rigorous code reviews identifying security holes, lazy patterns, and bad practices.
- **describe-design** – Researches a codebase and creates architectural documentation with Mermaid diagrams.
- **mlr3book-maintainer** – Diagnoses and fixes CI failures in the mlr3book's weekly build.
- **mlr3book-reviewer** – Reviews mlr3book chapters for compliance with the style guide and chapter structure.
- **mlr3ecosystem-release** – Prepares CRAN releases of packages in the mlr3 ecosystem.
- **mlr3gallery-maintainer** – Maintains the mlr3 gallery.
- **mlr3gallery-reviewer** – Reviews gallery posts on mlr-org.com for compliance with the style guide.
- **name-chunk** – Names unnamed R code chunks in `.qmd` files using the `[file-name]-[number]` pattern.
- **pr-create** – Creates a pull request, monitors GitHub CI, and debugs failures until CI passes.
- **r-package-setup** – Copies the shared config files from `package/` into a target R package.

Skills from [posit-dev](https://github.com/posit-dev/skills).
See this [help page](https://support.claude.com/en/articles/12512180-using-skills-in-claude) for more information on how to use skills in Claude.

# Reverse Dependencies Check

Scripts to create a conda environment that satisfies the dependencies of all reverse dependencies of an mlr3 package.
Includes dependencies of suggested packages.
Located in `revdepcheck`.
