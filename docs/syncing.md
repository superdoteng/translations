# Syncing translations with the app

The translations repository owns accepted catalogs under `catalogs/` on `main`.
CI publishes that directory as the generated `catalogs` branch. Never edit the
generated branch directly. The app vendors its contents at `crates/i18n/locales`;
repository images, GitHub configuration, and contributor documentation stay out.

The app records the imported snapshot in `crates/i18n/catalogs-revision`.
Its sync commands compare catalog files against that revision and use Git's
three-way merge to preserve independent edits and flag conflicts. App ancestry
and commit messages are never exported. Normal squash merges work in both repos;
no subtree trailers or special merge parents are needed in the app.

## Automatic catalog export

The Catalogs workflow validates each push to `main`, then regenerates and pushes
the `catalogs` branch. Documentation-only changes leave the generated snapshot
unchanged. PR checks are read-only; only the export job on `main` can write.
Export jobs are serialized, skip superseded snapshots, and use fast-forward pushes.

Wait for validation and export to succeed before importing accepted translations.
Investigate a diverged generated branch rather than force-pushing it. For recovery,
select **Run workflow** on the Catalogs workflow with branch `main`, or run:

```bash
gh workflow run catalogs.yml --repo superdoteng/translations --ref main
```

The same command works from a terminal or desktop agent session. A separate
desktop generation action is unnecessary.

## Import into the app

Syncing requires Git 2.43 or newer. Commit or stash app changes first, then run
from the app checkout:

```bash
just i18n-pull
```

The command fetches only the generated `catalogs` branch and stages its changes
alongside the new revision. Existing committed app catalog edits are preserved.
A repeated pull of the same revision does nothing. Review `git diff --cached`,
run `just i18n-check`, and commit the catalogs and revision together. Use the
app's normal squash PR workflow.

App validation installs its pinned Python dependencies and includes private Rust
call-site checks. The strict check reports the existing translation backlog;
review newly introduced errors separately. Catalogs are embedded in app releases,
so importing them does not update an installed app.

## Export app edits into a translations PR

Keep catalog edits in dedicated app commits. Before publishing, import accepted
upstream changes, review and validate them, and commit the import. Then prepare a
branch in a separate clean clone of this public repository:

```bash
# Run in the app checkout; adjust the checkout path and choose a new branch name.
just i18n-export ../translations improve-french
```

The command applies only catalog differences to current public `main` and creates
a translation-only commit. It handles upstream changes that arrived after the
app's last import, stopping on conflicts. It never copies app commits or pushes.
If the generated branch has not caught up with `main`, wait for CI and retry.
If these edits are already accepted upstream, no new commit is created.

Review and validate in the translations checkout before publishing:

```bash
cd ../translations
git diff origin/main...HEAD
# Set up local dependencies as described in CONTRIBUTING.md if needed.
bash catalogs/scripts/check-catalogs.sh --base origin/main
git push -u origin improve-french
gh pr create --repo superdoteng/translations --base main --head improve-french
```

Merge the PR using any allowed method, including squash. Wait for CI to publish
`catalogs`, then run `just i18n-pull` in the app and commit the accepted revision.
No intermediate catalog-root branch or subtree rejoin is needed.

## Conflicts and rollback

A failed import leaves its revision unchanged and may leave staged changes or
conflicts. Resolve the catalogs, stage the resolutions, then write the exact
revision printed by the command to `crates/i18n/catalogs-revision` and stage it.
Validate before committing. To abandon an import started from a clean checkout:

```bash
git restore --source=HEAD --staged --worktree -- crates/i18n/locales crates/i18n/catalogs-revision
```

A failed export leaves the prepared public branch for conflict resolution. Resolve
and stage its catalog changes, validate, and commit before opening the PR. Never
resolve conflicts by overwriting a whole catalog directory.

Revert a faulty app import with `git revert <commit>`; revert its revision change
as well as its catalogs. This lets a later pull retry the import. If the import was
squashed with other work, revert only its catalog and revision changes together.
Fix accepted upstream mistakes through a normal translations PR.

## Dependencies and licensing

The app receives `catalogs/LICENSE`, the shared validator, its pinned Python
requirements, and locale files. The repository root has the same license for
its tooling and documentation. Python validation dependencies are development-only
and do not ship in the app; review sources, advisories, and hashes on updates.
