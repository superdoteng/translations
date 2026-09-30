<p align="center">
  <a href="https://super.engineering">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="assets/app-icon-dark.png">
      <img src="assets/app-icon.png" alt="super.engineering" width="88" height="88">
    </picture>
  </a>
</p>

<h1 align="center">super.engineering translations</h1>

<p align="center">Help engineers work in their own language.</p>

<p align="center">
  <a href="https://github.com/superdoteng/translations/actions/workflows/catalogs.yml"><img alt="Catalog checks" src="https://github.com/superdoteng/translations/actions/workflows/catalogs.yml/badge.svg"></a>
  <a href="LICENSE"><img alt="MIT license" src="https://img.shields.io/badge/license-MIT-2ea44f?style=flat&labelColor=313131"></a>
  <a href="https://github.com/sponsors/superdoteng"><img alt="Sponsor" src="https://img.shields.io/badge/-ea4aaa?style=flat&logo=githubsponsors&logoColor=white"></a>
</p>

**Translate the experience. Keep the meaning.**

These catalogs supply the interface text for [super.engineering](https://super.engineering), the app for running many coding agents at once. Each language lives in `<locale>/main.ftl`, using [Project Fluent](https://projectfluent.org/). The app embeds a committed copy; builds and running apps do not fetch translations.

This repository is the canonical upstream for accepted catalog changes. It is private during setup and review. Publication requires the owner's explicit approval.

## Contribute

1. Create a branch from `main` and edit your language's `main.ftl`.
2. Validate locally with the commands below.
3. Open a PR targeting `main`. Explain the meaning or context of your changes; screenshots help when wording depends on space or placement.

Keep changes focused. Improve natural phrasing, consistency, and clarity. Preserve the intent of the English source, including keyboard shortcuts, product names, and technical terms where appropriate.

`en-US` defines message IDs and interpolation variables. `en-XA` is a development pseudo-locale that exposes layout and localization problems; it is not a human translation. New IDs, variable changes, and new languages need app-maintainer coordination. Adding a directory alone does not enable a language: app locale registration, language settings, and component mappings also need integration.

## Write Fluent

Message IDs form a stable contract with the app. Translate values, not IDs or variable names:

```ftl
welcome = Welcome, { $name }.
```

Preserve every variable required by the English message. Fluent selects let your language use its own plural rules; retain a default variant marked with `*`:

```ftl
items = { $count ->
    [one] One item
   *[other] { $count } items
    }
```

Keep select keys and fixed selectors meaningful to the app. Do not translate identifiers such as `$count` or a provider's selector value. Fluent may require different plural categories in your language; use [Fluent's syntax guide](https://projectfluent.org/fluent/guide/) for patterns and selects.

Preserve intentional Unicode directional isolates around embedded paths, commands, and mixed-direction text. Do not strip invisible characters as a formatting cleanup. For right-to-left languages, review the rendered result with an app maintainer.

The four English-only variables on `chat-greeting-morning` (`count`, `project`, `provider`, `variant`) support an experiential empty state enabled only for exact `en-US`. Other locales use their ordinary morning greeting. These explicit exceptions live in `scripts/check-catalogs.sh`; the validator rejects exceptions that no longer exist in English.

## Validate

You need Bash, ripgrep (`rg`, with PCRE2 support), Python 3.10+, and standard Unix tools. On macOS, install ripgrep and Python through your usual package manager. On Ubuntu, install `ripgrep` if it is not already available.

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install --require-hashes -r requirements.txt
bash scripts/check-catalogs.sh
```

Checks reject malformed Fluent, duplicate IDs, missing or unexpected IDs, variable mismatches, and stale English-only variable exceptions. They work without the app repository or GPUI. CI runs the same checks for PRs and pushes to `main`.

### Current translation backlog

The initial snapshot preserves all 21 catalogs byte for byte. It contains 345 distinct untranslated English IDs and seven distinct obsolete IDs across the 20 non-English catalogs (including `en-XA`). The strict check currently reports 6,657 missing IDs, 138 obsolete IDs, and 544 missing variable pairs; these totals count each affected locale separately. All catalogs parse successfully. CI will fail the contract check until this existing backlog is reconciled; it is not waived or hidden by a baseline allowance.

The app falls back to English for missing messages. Leave untranslated messages absent rather than adding empty Fluent values. Contributions can repair a focused part of the backlog; do not replace existing translations wholesale with English merely to make the check green.

The syntax parser is Mozilla's Apache-2.0 [fluent.syntax](https://github.com/projectfluent/python-fluent), version 0.19.0, with `typing_extensions` 4.16.0 (PSF license). Both packages are pinned by version and wheel hash in `requirements.txt`; neither ships in the app. Review updates against their upstream sources, refresh hashes from PyPI, and rerun validation.

## Sync with the app

Maintainers run these commands from the app repository. The prefix is `crates/i18n/locales`, upstream is `https://github.com/superdoteng/translations.git`, and upstream's accepted branch is `main`. Always use squashed imports. Start imports with a clean working tree; never reconcile by copying one directory over the other.

The initial app import records Git's native `git-subtree-dir`, `git-subtree-mainline`, and `git-subtree-split` trailers on the import merge. This establishes the export boundary at the fresh upstream snapshot. A plain squashed add of a previously tracked directory can export older app commit messages on subsequent pushes, so preserve these trailers and inspect exported history before pushing. Initial export must never use `subtree split` on pre-extraction app history.

Set up once per app checkout:

```bash
git remote add translations https://github.com/superdoteng/translations.git
```

Activate a Python environment with the subtree's pinned requirements before running app validation:

```bash
python3 -m venv crates/i18n/locales/.venv
. crates/i18n/locales/.venv/bin/activate
python -m pip install --require-hashes -r crates/i18n/locales/requirements.txt
just i18n-check
```

### App to upstream

Commit catalog changes separately from app code, with commit messages suitable for export. Future subtree exports retain these messages. Review the exported history before pushing; it must contain only translations and contribution tooling.

```bash
just i18n-check
git subtree push --prefix=crates/i18n/locales translations translate-topic
gh pr create --repo superdoteng/translations --base main --head translate-topic
```

Review the PR diff and exported commit messages before merging, including any validation failures from the documented backlog. Merge the upstream PR with a history-preserving merge commit, then import `main` to reconcile ancestry. Do not force-push. Squash/rebase PR merges need separate workflow verification before adoption.

### Upstream to app

```bash
git subtree pull --prefix=crates/i18n/locales --squash translations main
just i18n-check
```

Pulls make explicit app commits. Each app revision fixes the exact catalogs shipped with that release. Keep English keys aligned with the app's call sites; the app wrapper also checks Rust references.

### Concurrent edits and conflicts

Import upstream first. Git merges independent edits and reports overlapping changes. For conflicts, edit the affected Fluent message, preserve both contributors' intent against the current English contract, stage the resolution, validate, and finish the merge commit. Then export any remaining local changes through a PR. Git cannot choose the correct wording for you.

Repeat pulls should introduce no duplicate changes. If ancestry looks wrong, stop and inspect the subtree merge history rather than using a blind copy or force push.

### Roll back

Revert the offending app change or import (use `git revert -m 1 <merge>` for an import merge), then validate against current app references. Correct upstream through a normal PR; do not rewrite shared history. A reverted import remains part of Git ancestry, so restoring it requires reverting the revert or a new upstream fix, not pulling the same revision again.

## License

MIT, copyright © 2026 super.engineering. This applies to the catalogs and contribution tooling in this repository. The app's proprietary license is unchanged. Third-party validation packages retain their own licenses.
