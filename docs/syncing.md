# Syncing translations with the app

For maintainers with access to the proprietary desktop source. Community contributors only need [CONTRIBUTING.md](../CONTRIBUTING.md).

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

## App to upstream

Commit catalog changes separately from app code, with commit messages suitable for export. Future subtree exports retain these messages. Review the exported history before pushing; it must contain only translations and contribution tooling.

```bash
just i18n-check
git subtree push --prefix=crates/i18n/locales translations translate-topic
gh pr create --repo superdoteng/translations --base main --head translate-topic
```

Review the PR diff and exported commit messages before merging, including any validation failures from the documented backlog. Merge the upstream PR with a history-preserving merge commit, then import `main` to reconcile ancestry. Do not force-push. Squash/rebase PR merges need separate workflow verification before adoption.

## Upstream to app

```bash
git subtree pull --prefix=crates/i18n/locales --squash translations main
just i18n-check
```

Pulls make explicit app commits. Each app revision fixes the exact catalogs shipped with that release. Keep English keys aligned with the app's call sites; the app wrapper also checks Rust references.

## Concurrent edits and conflicts

Import upstream first. Git merges independent edits and reports overlapping changes. For conflicts, edit the affected Fluent message, preserve both contributors' intent against the current English contract, stage the resolution, validate, and finish the merge commit. Then export any remaining local changes through a PR. Git cannot choose the correct wording for you.

Repeat pulls should introduce no duplicate changes. If ancestry looks wrong, stop and inspect the subtree merge history rather than using a blind copy or force push.

## Roll back

Revert the offending app change or import (use `git revert -m 1 <merge>` for an import merge), then validate against current app references. Correct upstream through a normal PR; do not rewrite shared history. A reverted import remains part of Git ancestry, so restoring it requires reverting the revert or a new upstream fix, not pulling the same revision again.

## Validation dependencies

Standalone syntax validation uses Mozilla's Apache-2.0 [fluent.syntax](https://github.com/projectfluent/python-fluent) 0.19.0 and `typing_extensions` 4.16.0 (PSF license). Both are pinned by version and wheel hash in `requirements.txt`; neither ships in the app. Review upstream sources and advisories, refresh hashes from PyPI, and rerun validation when updating them.
