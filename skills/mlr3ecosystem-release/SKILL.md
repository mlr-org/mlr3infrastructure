---
name: mlr3ecosystem-release
description: >
  Prepare a CRAN release of packages in the mlr3 ecosystem.
tools: Read, Edit, Glob, Grep, Bash, Write, AskUserQuestion, WebFetch
---

# mlr3ecosystem-release

Your role is to prepare a CRAN release of packages in the mlr3 ecosystem.

## Workflow


### Step 1: Validation

First, check that the prerequisites are available (in this order for
efficiency):

1. Check that the working directory contains a file called `DESCRIPTION`. If
   not, inform the user that this must be run from an R package root directory
   and stop.
2. Use `Rscript -e 'utils::packageVersion("usethis")'` to check if the `usethis`
   package is installed. If not, instruct the user to install it with
   `install.packages("usethis")`, then stop.
3. Determine the GitHub URL for the repository. Try `gh repo view --json url`.
   If that fails, diagnose the error:
   - If `gh` is not installed, try `git remote -v` to find a GitHub URL.
   - If `gh` is installed but not authenticated, suggest running `gh auth login`.
   - If no GitHub remote is found, warn the user that the GitHub release issue
     and pull request steps will be skipped.

### Step 2: Initialization

Next, determine the current package's name and version. Read the `DESCRIPTION`
file and extract the `Version:` and `Package:` fields from it.

Then, check if a `NEWS.md` file exists. If it does, read the first section (the
unreleased changes for the version being prepared). You will use this in the
next two steps: first to catch any undocumented changes (Step 3), then to
suggest an appropriate release type (Step 4).

### Step 3: Check git history for missing NEWS.md entries

The goal here is to catch anything that landed in the repo since the last
release but wasn't documented in `NEWS.md`. Omissions are easy to miss during
development, and this is the last chance to add them before CRAN submission.

This step must run **before** the version number is calculated: the release
type (and therefore the new version) is inferred from what `NEWS.md` contains,
so the NEWS must be complete first. For example, an undocumented breaking
change would otherwise lead to a patch or minor release when a major release is
warranted.

First, find the last release tag and list commits since then:

```bash
LAST_TAG=$(git tag --sort=-version:refname | head -1)
git log "${LAST_TAG}..HEAD" --oneline --no-merges
```

If there are no tags yet (first release), use the initial commit:

```bash
git log --oneline --no-merges
```

Then read the first section of `NEWS.md` (the unreleased changes for the
version being prepared). Compare the commit list against the NEWS entries: look
for commits that describe user-facing changes (new features, bug fixes,
behaviour changes, deprecations) that do not appear to have a corresponding
entry.

Ignore commits that are purely internal and don't affect users, such as:
- CI / GitHub Actions changes
- Code style / linting fixes
- Dependency bumps that have no user-visible effect
- Merge commits

If you find likely missing entries, summarise them clearly for the user and
ask whether they want to add them to `NEWS.md` before proceeding. If the user
says yes, open `NEWS.md` and add the missing entries under the first
(unreleased) section, then confirm with the user before moving on.

### Step 4: Determine the release type and new version

With `NEWS.md` now complete, read the first section again and use it to suggest
an appropriate release type:

- If the NEWS mentions "breaking changes", "breaking", "BREAKING", or similar
  language, suggest a **Major** release.
- If the NEWS mentions only "bug fixes", "fixes", "patch", or similar language
  with no new features, suggest a **Patch** release.
- Otherwise (new features, improvements, enhancements), suggest a **Minor**
  release.

Display the current version to the user and ask them what type of release this
should be using the AskUserQuestion tool. Make the suggested release type the
first option with "(Recommended)" appended to the label:

Question: "What type of release is this?"
Header: "Release type"
Options (with recommended option first):
- Major (X.0.0) - Breaking changes (add "(Recommended)" if suggested)
- Minor (x.X.0) - New features but without breaking changes (add "(Recommended)" if suggested)
- Patch (x.x.X) - Bug fixes only (add "(Recommended)" if suggested)

Calculate the new version by manipulating the current version according to the
user's answer. For example:

- Current version `1.2.3` + Major release → `2.0.0`
- Current version `1.2.3` + Minor release → `1.3.0`
- Current version `1.2.3` + Patch release → `1.2.4`
- Current version `0.2.1.9000` + Patch release → `0.2.2`
- Current version `0.2.1.9003` + Minor release → `0.3.0`

Note: If the current version ends in `.9xxx` (R-style development versions),
strip that suffix before calculating the new version.

Display: "Preparing release checklist for ${PACKAGE_NAME} ${CURRENT_VERSION} → ${NEW_VERSION}".

### Step 5: Check current CRAN check results

Before making any changes, check whether the package currently has any issues on
CRAN. Fetch the CRAN checks page for the package:

```
https://cloud.r-project.org/web/checks/check_results_${PACKAGE_NAME}.html
```

Use the WebFetch tool with the prompt "Extract ALL check results from the table.
For each row list the flavour and the status (OK, NOTE, WARNING, or ERROR).
Also list any additional issues noted below the table." to retrieve and parse
the page.

**If the page is not found (404):** The package is not yet on CRAN (first
release). Skip this step silently and continue.

**If any check flavour shows ERROR, WARNING, or NOTE:** Display the issues
clearly to the user, including the affected flavour(s) and their status, and
inform them that existing CRAN check issues should be resolved before submitting
a new release. Stop the workflow.

**If all check flavours show OK:** Inform the user that all CRAN checks are
passing and continue with the release workflow.

### Step 6: Create a new release branch

Check whether a branch named `release` already exists (locally or on the
remote). If it does, ask the user using AskUserQuestion:

Question: "A 'release' branch already exists. How should we proceed?"
Header: "Existing branch"
Options:
- Delete it and create a fresh one from main
- Abort and let me handle it manually

If the user chooses to delete it, run:

```bash
git branch -D release
git push origin --delete release 2>/dev/null || true
```

Then create a new branch from `main`:

```bash
git checkout main
git pull origin main
git checkout -b release
```

### Step 7: Create a GitHub release issue

If `gh` is available and authenticated, run the following R command to create a
GitHub release issue:

```bash
Rscript -e 'usethis::use_release_issue(version = "${NEW_VERSION}")'
```

After the command succeeds, retrieve the issue number that was just created:

```bash
gh issue list --limit 1 --json number --jq '.[0].number'
```

Store this as `${ISSUE_ID}` for use in Step 12.

If `gh` is not available, skip this step and inform the user that they can
create the release issue manually later. In that case, `${ISSUE_ID}` will be
unknown.

### Step 8: Increase the version number

Run the following R command to update the version in `DESCRIPTION` and `NEWS.md`:

```bash
Rscript -e 'usethis::use_version(which = "major")'
```

Replace `"major"` with `"minor"` or `"patch"` depending on the release type
chosen in Step 4.

### Step 9: Check for invalid URLs

Run the following R command to check for invalid URLs:

```bash
Rscript -e 'urlchecker::url_check()'
```

If there are any invalid URLs, ask the user if they should be fixed.

### Step 10: Check for Remotes field

Check for the presence of the `Remotes` field in the `DESCRIPTION` file.
If it is present, ask the user if it should be removed (CRAN does not allow
packages with a `Remotes` field).

### Step 11: Update cran-comments.md

The `cran-comments.md` file documents the test environments and any notes for
the CRAN team. CRAN reviewers read this file, so it's important to keep it
current for every submission.

Check whether `cran-comments.md` exists:

- **If it does not exist**, create it with this template:

  ```markdown
  ## Test environments

  - local: R version x.y.z, Platform

  ## R CMD check results

  0 errors | 0 warnings | 0 notes

  ## Reverse dependencies

  Checked with revdepcheck::revdep_check(). No new problems.
  ```

  Inform the user that `cran-comments.md` has been created and they should fill
  in the actual test environments and R CMD check results before submitting to
  CRAN.

- **If it does exist**, read it and inform the user that they should update it
  for the new release (e.g., updated R version, new check results, response to
  any previous CRAN reviewer comments).

### Step 12: Push to GitHub and open a pull request

Commit the changes with the message `release: ${NEW_VERSION}`:

```bash
git add DESCRIPTION NEWS.md
git commit -m "release: ${NEW_VERSION}"
```

Push the branch and open a pull request:

```bash
git push -u origin release
gh pr create \
  --title "release: ${NEW_VERSION}" \
  --body "Closes #${ISSUE_ID}" \
  --base main \
  --head release
```

If `${ISSUE_ID}` is unknown (because Step 7 was skipped), omit the `--body`
flag and add it manually after the PR is created.

Show the user the pull request URL on success.

If `gh` is not available, display the branch name and instruct the user to
open a pull request manually on GitHub.

Inform the user that they should now perform a reverse dependency check, fix any issues found,
and submit the release to CRAN. Wait until the user confirms that the release has
been accepted by CRAN before proceeding to the next step.

### Step 13: Merge the pull request

IMPORTANT: Always use `--squash` when merging. A squash merge is mandatory — never use a regular merge or rebase merge.

Merge the pull request and checkout the main branch:

```bash
gh pr merge --squash --delete-branch release
git checkout main
git pull origin main
```

### Step 14: Add a GitHub release

Use this exact R command — do not substitute `gh release create` or any other
approach. `usethis::use_github_release()` reads `NEWS.md` to populate the
release notes and tags the commit correctly, which manual approaches would miss.

```bash
Rscript -e 'usethis::use_github_release()'
```

### Step 15: Push dev version to GitHub

Use this exact R command — do not edit `DESCRIPTION` by hand or use a different
version string. `usethis::use_dev_version()` appends `.9000` in the correct
R-package convention and adds the development section header to `NEWS.md`.

```bash
Rscript -e 'usethis::use_dev_version(push = FALSE)'
```

Commit and push the changes:

```bash
git add DESCRIPTION NEWS.md
git commit -m "release: ${NEW_VERSION}.9000"
git push origin main
```

The workflow is now complete. Inform the user that the release of `${PACKAGE_NAME} ${NEW_VERSION}` is done.
