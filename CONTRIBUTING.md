# Contributing translations

You can help using the released desktop app and this repository. The app source is private; you do not need it to report text or submit translations.

## Report text in the app

Use the [translation report form](https://github.com/superdoteng/translations/issues/new?template=untranslated.yml) for untranslated, incorrect, or clipped text. Include a screenshot, the display language, the app version, and steps to reach the screen. Copy the affected text and suggest a translation if you can. Message IDs are optional; maintainers can locate them from your report.

## Edit a translation

1. Fork this repository and create a branch from `main`, or edit a catalog through GitHub's web editor.
2. Find the visible text in `en-US/main.ftl`, then find the same message ID in your language's `main.ftl`. If it is missing, add that message with your translation. If you cannot find the text, report it instead.
3. Translate the value, keeping the ID and variables unchanged. Preserve meaning, keyboard shortcuts, product names, and technical terms where appropriate.
4. Open a PR against `main`. State the language, affected IDs, and why the wording is better. Link a report or attach a screenshot from the released app when screen context matters.

`en-US` defines the message contract. `en-XA` is a development pseudo-locale, not a language to translate. Ask maintainers before changing source IDs or variables.

Editing a `.ftl` file does not change the installed app: its catalogs are bundled with each release. You are not expected to build the app or provide an in-app preview of your proposed wording. Maintainers review the language and test formatting, layout, and app integration before shipping.

## Fluent basics

Translate the text, leaving `welcome` and `$name` intact:

```ftl
welcome = Welcome, { $name }.
```

- Preserve interpolation variables and fixed select keys used by the app. Use your language's plural categories and retain a default variant marked `*`. See the [Fluent guide](https://projectfluent.org/fluent/guide/) for plural/select examples.
- Preserve intentional directional isolates around paths, commands, and mixed-direction text. Ask for maintainer review of right-to-left layout.
- Leave messages you have not translated absent rather than adding empty values or replacing existing translations with English.

The four English-only variables on `chat-greeting-morning` (`count`, `project`, `provider`, `variant`) are intentional exceptions for an English-only empty state. Other locales use their ordinary greeting; the exceptions are recorded in `scripts/check-catalogs.sh`.

## Check your changes (optional)

CI runs the checks on your PR. To run them yourself, you need Bash, ripgrep (`rg` with PCRE2), Python 3.10+, and standard Unix tools. Run from this repository:

```bash
python3 -m venv .venv
. .venv/bin/activate
python -m pip install --require-hashes -r requirements.txt
bash scripts/check-catalogs.sh
```

These checks validate Fluent syntax, message IDs, variables, and duplicates without the app source. They cannot show how your changes look in the app.

The catalogs have an existing backlog of missing and obsolete IDs, so the strict check currently fails even without edits. Keep your PR focused; maintainers check for new errors and improvements rather than asking you to repair every locale. Missing messages fall back to English in the app.

## New languages and licensing

Open an issue before starting a new language. Maintainers must add app support as well as a catalog; a new directory alone does not enable the language.

Contributions to this repository use the [MIT license](LICENSE). App syncing is handled by maintainers using [docs/syncing.md](docs/syncing.md).
