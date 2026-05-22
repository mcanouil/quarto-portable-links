# Portable Links

A Quarto extension that rewrites relative cross-page links to absolute `site-url` links in non-HTML output formats, so they keep working away from the rendered HTML site.

In a Quarto website or book, relative links such as `[other page](other.qmd)` resolve only within the HTML site.
When the same document is rendered to PDF, DOCX, Typst, an HTML slide deck, or another format, those targets do not exist alongside the output and the links break.
This filter rewrites them to absolute URLs built from the project's `site-url`, pointing readers to the live HTML site.
HTML slide formats (`revealjs`, `slidy`, `s5`, `dzslides`, `slideous`) are self-contained decks where cross-page links do not resolve, so they are rewritten too.
Plain HTML, format extensions built on the `html` base format, and `epub` are left untouched because their relative cross-page links already resolve.

## Installation

```bash
quarto add mcanouil/quarto-portable-links
```

This will install the extension under the `_extensions` subdirectory.
If you are using version control, you will want to check in this directory.

## Usage

The filter relies on the project's `site-url`.
Set it under `website` or `book` in `_quarto.yml`:

```yaml
website:
  site-url: "https://example.com/my-site"
```

To use the extension, add the following to your document's front matter:

```yaml
filters:
  - portable-links
```

Then write relative cross-page links as usual:

```markdown
See the [methods page](methods.qmd) and [the appendix](appendix.html#notes).
```

When rendered to a non-HTML format, those links become absolute, for example `https://example.com/my-site/methods.html` and `https://example.com/my-site/appendix.html#notes`.

A link is rewritten when its target:

- points to a `.qmd` or `.html` file, optionally with a `#fragment` or `?query`.
- is relative (no URI scheme such as `https:` or `mailto:`, and not a protocol-relative `//host` URL).
- is not a pure in-page anchor (`#section`).

Rewriting normalises `.qmd` targets to `.html` and strips a leading `./`.

## Configuration

Disable the filter for a document or project via the front matter:

```yaml
extensions:
  portable-links:
    enabled: false
```

### Options

| Option    | Type    | Default | Description                            |
| --------- | ------- | ------- | -------------------------------------- |
| `enabled` | boolean | `true`  | Enable or disable link rewriting.      |

## Limitations

- A project `site-url` is required.
  When it is missing, the filter emits a warning and leaves links unchanged.
- Plain HTML, format extensions built on the `html` base format, and `epub` are intentionally skipped.
  HTML slide formats (`revealjs`, `slidy`, `s5`, `dzslides`, `slideous`) are rewritten.

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).

Rendered output:

- [HTML](https://m.canouil.dev/quarto-portable-links/).
