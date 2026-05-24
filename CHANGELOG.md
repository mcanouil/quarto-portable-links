# Changelog

## Unreleased

### Bug Fixes

- fix: Strip a leading `/` from root-relative targets so rewritten URLs do not contain a double slash.

## 0.1.0 (2026-05-22)

### New Features

- feat: Rewrite relative `.qmd`/`.html` cross-page links to absolute `site-url` links in non-HTML formats.
- feat: Treat HTML slide formats (`revealjs`, `slidy`, `s5`, `dzslides`, `slideous`) as non-HTML so their cross-page links are rewritten.
