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

Interface translations for [super.engineering](https://super.engineering). Each language lives in `<locale>/main.ftl`, using [Fluent](https://projectfluent.org/).

The desktop app is proprietary. You can contribute translations or report untranslated screens without access to its source. Maintainers test changes in the app and include accepted translations in a future release.

## Help translate

- **Found untranslated or incorrect text?** [Report it](https://github.com/superdoteng/translations/issues/new?template=untranslated.yml) with a screenshot. Language and other details are optional; no message ID needed.
- **Want to improve a translation?** Read [CONTRIBUTING.md](CONTRIBUTING.md), edit your language's catalog, and open a PR against `main`.
- **Want to add a language?** [Open an issue](https://github.com/superdoteng/translations/issues) first so maintainers can coordinate app support.

## Checks

PRs run standalone catalog checks against their target revision. CI fails for new ID or variable mismatches, removed catalogs, malformed Fluent, duplicates, and stale variable exceptions; existing ID/variable issues are reported as a backlog count. Pushes compare with the previous branch revision, and manual runs compare with the previous commit. Missing messages fall back to English.

[Local checks are optional](CONTRIBUTING.md#check-your-changes-optional) and need no app source. The default check reports the complete backlog; use `bash scripts/check-catalogs.sh --base REF` to check for regressions against a Git revision.

[App syncing instructions](docs/syncing.md) are for maintainers with access to the desktop source.

## License

[MIT](LICENSE) for these catalogs and contribution tooling. The desktop app remains proprietary.
