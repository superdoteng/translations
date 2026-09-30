# Contributing translations

You can help using the released desktop app and this repository. The app source is private; you do not need it to report text or submit translations.

## Report text in the app

Use the [translation report form](https://github.com/superdoteng/translations/issues/new?template=untranslated.yml) for untranslated, incorrect, or clipped text. A screenshot is enough. Add the display language, context, or suggested wording if useful. No message ID is needed; maintainers can locate the text from your screenshot.

## Edit a translation in your browser

You need a signed-in GitHub account. You can use GitHub's web editor without cloning this repository or building the app:

1. Find the visible English text in [en-US/main.ftl](en-US/main.ftl) and note its message ID.
2. Open your language's `<locale>/main.ftl` in [the repository](https://github.com/superdoteng/translations). For example, French is [fr-FR/main.ftl](fr-FR/main.ftl). Find the same ID; if it is missing, add it with your translation. If you cannot find the English message, report it instead.
3. Click the pencil icon to edit. If prompted, choose **Fork this repository**.
4. Translate the value, keeping the ID and variables unchanged. Preserve meaning, keyboard shortcuts, product names, and technical terms where appropriate.
5. Click **Commit changes…**, enter a short summary, then **Propose changes**. If you have write access, choose a new branch rather than committing to `main`.
6. Review the proposed changes and choose **Create pull request**, targeting `superdoteng/translations` on `main`. State the language and affected IDs, and link your report or screenshot when helpful.

See [GitHub's file-editing guide](https://docs.github.com/en/repositories/working-with-files/managing-files/editing-files#editing-files-in-another-users-repository) if the interface differs.

`en-US` defines the message contract. `en-XA` is a development pseudo-locale, not a language to translate. Ask maintainers before changing source IDs or variables.

Editing a `.ftl` file does not change the installed app: its catalogs are bundled with each release. You are not expected to build the app or provide an in-app preview of your proposed wording. Maintainers review the language and test formatting, layout, and app integration before shipping.

## Ask an agent to help

Attach your screenshot and replace the task and language placeholders before sending this prompt to your agent:

```text
Help with a translation problem in super.engineering.
Repository: https://github.com/superdoteng/translations
Task: [report an issue / propose a catalog fix]
Target language: [language, or unknown]
Screenshot: attached

Read AGENTS.md and CONTRIBUTING.md in that repository. Use the screenshot
and English catalog to identify the text. For a fix, edit only the relevant
translation and preserve its message ID, variables, and Fluent syntax.
If you cannot identify the message, report it rather than guessing.
Run standalone checks if possible and distinguish new errors from the
known backlog. App testing is handled by maintainers.
Submit the issue or PR through GitHub if you have access. Otherwise,
prepare the report or patch for me to submit. No desktop source is needed.
```

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
