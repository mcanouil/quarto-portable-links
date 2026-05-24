# Changelog

## Unreleased

### New Features

- feat: Preserve a subpath in `site-url` (e.g. a GitHub Pages project subpath) when rewriting links, so absolute URLs keep the subdirectory.

## 0.1.0 (2026-05-22)

### New Features

- feat: Rewrite relative `.qmd`/`.html` cross-page links to absolute `site-url` links in non-HTML formats.
- feat: Treat HTML slide formats (`revealjs`, `slidy`, `s5`, `dzslides`, `slideous`) as non-HTML so their cross-page links are rewritten.
