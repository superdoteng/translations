# Syncing translations with the app

The public-facing repository owns accepted translations under `catalogs/` on `main`. The `catalogs` branch is a generated subtree split of that directory; never edit it directly. The app vendors that branch at `crates/i18n/locales`. Repository images, GitHub configuration, and contributor documentation stay outside the app.

Use dedicated catalog commits and inspect every exported commit message before pushing. If an app merge introduces unrelated commit messages into the export, stop and re-establish the subtree boundary before exporting. Never publish app history or reconcile conflicting catalogs with a directory overwrite.

## Automatic catalog export

The Catalogs workflow validates each push to `main`, then regenerates and pushes the `catalogs` branch. Documentation-only changes produce an unchanged split. PR validation remains read-only; only the export job on `main` has write permission. Export jobs are serialized, skip superseded snapshots, and use ordinary fast-forward pushes so a stale job cannot overwrite a newer export.

Wait for both validation and export to succeed before importing accepted translations into the app. If the generated branch diverges, investigate it rather than force-pushing.

For recovery, select **Run workflow** on GitHub's Catalogs workflow with branch `main`, or trigger the same workflow from any terminal or desktop agent session:

```bash
gh workflow run catalogs.yml --repo superdoteng/translations --ref main
```

Manual runs use the same validation, serialization, and publishing checks. No separate desktop generation action is needed.

## Import into the app

Run from a clean app checkout with the `translations` remote pointing to `https://github.com/superdoteng/translations.git`:

```bash
git subtree pull --prefix=crates/i18n/locales --squash translations catalogs
python3 -m venv crates/i18n/locales/.venv
. crates/i18n/locales/.venv/bin/activate
python -m pip install --require-hashes -r crates/i18n/locales/requirements.txt
just i18n-check
```

App validation includes private Rust call-site checks and reports the full existing catalog backlog. Review newly introduced errors separately. Catalogs are embedded in each app release; imports do not update an installed app.

## Export app edits into a translations PR

In the app checkout, validate the changes, commit catalog edits separately, and inspect the split before pushing:

```bash
catalog_commit=$(git subtree split --prefix=crates/i18n/locales)
git fetch translations catalogs
git log --oneline translations/catalogs.."$catalog_commit"
git diff translations/catalogs "$catalog_commit"
git push translations "$catalog_commit":refs/heads/catalog-update-topic
```

The exported branch contains a catalog tree at its root, so it is not a PR branch against translations `main`. Integrate it into `catalogs/` in a clean translations checkout:

```bash
git fetch origin main catalog-update-topic
git switch -c translate-topic origin/main
git subtree split --prefix=catalogs --rejoin --squash
git subtree merge --prefix=catalogs --squash origin/catalog-update-topic
bash catalogs/scripts/check-catalogs.sh --base origin/main
git push -u origin translate-topic
gh pr create --repo superdoteng/translations --base main --head translate-topic
```

Review and merge the PR with a merge commit to preserve subtree ancestry. Wait for the Catalogs workflow to update `catalogs`, then import it into the app and delete the temporary topic/export branches. Squash/rebase merges need separate workflow verification before adoption.

## Conflicts, boundaries, and rollback

Import accepted upstream changes before exporting local changes. Resolve overlapping edits against the current English keys and variables, validate, and finish the merge. Repeated imports should not duplicate changes.

The app's boundary merge records native `git-subtree-dir`, `git-subtree-mainline`, and `git-subtree-split` trailers. Preserve both parents and these trailers when rewriting history. The split must refer to the catalog-only snapshot, never the full repository root.

Revert a faulty app import with `git revert -m 1 <merge>` and validate against current app references. Fix upstream through a normal PR. A reverted import remains in ancestry; restoring it requires reverting the revert or a new upstream fix.

## Dependencies and licensing

The app receives `catalogs/LICENSE`, the shared validator, its pinned Python requirements, and locale files. The repository root also contains the same license for repository tooling and documentation. Python validation dependencies are development-only and do not ship in the app; review sources, advisories, and hashes when updating them.
