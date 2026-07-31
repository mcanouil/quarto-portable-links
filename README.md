# Portable Links

A Quarto extension that rewrites relative cross-page links to absolute `site-url` links in non-HTML output formats, so they keep working away from the rendered HTML site.

In a Quarto website or book, relative links such as `[other page](other.qmd)` resolve only within the HTML site.
When the same document is rendered to PDF, DOCX, Typst, an HTML slide deck, or another format, those targets do not exist alongside the output and the links break.
This filter rewrites them to absolute URLs built from the project's `site-url`.

## Installation

```bash
quarto add mcanouil/quarto-portable-links@0.2.0
```

This will install the extension under the `_extensions` subdirectory.
If you are using version control, you will want to check in this directory.

## Documentation

The full documentation lives at <https://m.canouil.dev/quarto-portable-links/>: the rewriting rules, which formats are affected, and a Typst rendering of the site itself whose links point back at it.

[`example.qmd`](example.qmd) is a short, standalone starting point you can copy.

## Licence

[MIT](https://github.com/mcanouil/quarto-portable-links?tab=MIT-1-ov-file#readme).
