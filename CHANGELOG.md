# Changelog

## Unreleased

## 0.2.0 (2026-05-31)

### Bug Fixes

- fix: Warn when `QUARTO_EXECUTE_INFO` exists but cannot be parsed (unreadable file or invalid JSON), before falling back to document metadata; previously the fallback was silent and misconfiguration was hard to diagnose.
- fix: Anchor the `.qmd`/`.html` match to end-of-path (`.ext` at end-of-string, or before `#`/`?`) so targets such as `methods.qmd.backup` are no longer treated as cross-page links.

### Documentation

- docs: Clarify that `site-url` belongs in `_quarto.yml` or `_quarto.yaml` (project config) and never in document front matter; the missing-`site-url` warning now restates this.
- docs: Add nested-path, root-relative, current-directory, query-string, and non-match cases to the example, and extend the before/after table accordingly.

### Refactoring

- refactor: Extract the HTML slide-format set into the shared `_modules/slide-formats.lua` module so prism and portable-links agree on what counts as a slide format; the canonical source lives in `mcanouil-skills/skills/creating-quarto-extension/assets/modules` and is copied into each extension on release.
- refactor: Reset `site_url` at the start of `Meta` so batch renders cannot leak state across documents.

## 0.1.2 (2026-05-24)

### Bug Fixes

- fix: Strip a leading `/` from root-relative targets so rewritten URLs do not contain a double slash.

## 0.1.0 (2026-05-22)

### New Features

- feat: Rewrite relative `.qmd`/`.html` cross-page links to absolute `site-url` links in non-HTML formats.
- feat: Treat HTML slide formats (`revealjs`, `slidy`, `s5`, `dzslides`, `slideous`) as non-HTML so their cross-page links are rewritten.
