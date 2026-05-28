--- Portable Links - Filter
--- @module "portable-links"
--- @license MIT License
--- @copyright 2026 Mickaël Canouil
--- @author Mickaël Canouil
--- @brief Rewrite relative cross-page links to absolute site-url links.
--- @description In non-HTML output formats, relative links to other pages
--- in a Quarto website or book project are broken because the target pages
--- do not exist alongside the rendered output. This filter rewrites those
--- links to absolute URLs built from the project's site-url, so readers can
--- follow them to the live HTML site. HTML slide formats (revealjs, slidy,
--- s5, dzslides, slideous) are self-contained decks where cross-page links
--- do not resolve either, so they are rewritten too. Plain HTML, format
--- extensions built on the html base format, and epub are left untouched
--- because their relative cross-page links already resolve.

--- Extension name constant
local EXTENSION_NAME = 'portable-links'

local log = require(quarto.utils.resolve_path('_modules/logging.lua'):gsub('%.lua$', ''))
local slide_formats = require(quarto.utils.resolve_path('_modules/slide-formats.lua'):gsub('%.lua$', ''))

-- ============================================================================
-- MODULE-LEVEL VARIABLES
-- ============================================================================

--- @type string|nil The resolved site URL from project metadata
local site_url = nil

--- @type table<string, boolean> Per-document set of slide formats, seeded
--- from the canonical slide-format set and extended via
--- `extensions.portable-links.extra-slide-formats`.
local extra_slide_formats = {}

-- ============================================================================
-- HELPER FUNCTIONS (PRIVATE)
-- ============================================================================

--- Check whether the filter is disabled via extensions.portable-links.enabled.
--- @param meta table The document metadata table
--- @return boolean True if the filter is explicitly disabled
local function is_disabled(meta)
  local config = meta['extensions'] and meta['extensions'][EXTENSION_NAME]
  if not config or config['enabled'] == nil then
    return false
  end
  return pandoc.utils.stringify(config['enabled']) == 'false'
end

--- Read the user-declared extra slide formats from document metadata.
--- Accepts a string (single value) or a list (multiple values).
--- Empty values are ignored. The set is keyed by format name for O(1) lookup.
--- @param meta table The document metadata table
--- @return table<string, boolean> The set of additional slide-format names
local function read_extra_slide_formats(meta)
  local result = {}
  local config = meta['extensions'] and meta['extensions'][EXTENSION_NAME]
  if not config then return result end

  local extras = config['extra-slide-formats']
  if extras == nil then return result end

  -- A single string value is treated as a one-element list.
  if extras.t == 'MetaInlines' or type(extras) == 'string' then
    local name = pandoc.utils.stringify(extras)
    if name ~= '' then result[name] = true end
    return result
  end

  if extras.t == 'MetaList' or (type(extras) == 'table' and #extras > 0) then
    for _, entry in ipairs(extras) do
      local name = pandoc.utils.stringify(entry)
      if name ~= '' then result[name] = true end
    end
  end

  return result
end

--- Check whether the current output is an HTML-based slide format.
--- These decks are single self-contained outputs, so relative cross-page
--- links do not resolve and must be rewritten like other non-HTML formats.
--- Built-in members come from the shared `_modules/slide-formats` module;
--- per-document additions come from `extra-slide-formats`.
--- @return boolean True for any built-in or user-declared slide format
local function is_html_slides()
  for name in pairs(slide_formats.formats) do
    if quarto.doc.is_format(name) then return true end
  end
  for name in pairs(extra_slide_formats) do
    if quarto.doc.is_format(name) then return true end
  end
  return false
end

--- Read site-url from QUARTO_EXECUTE_INFO project metadata.
--- Tries website.site-url first, then book.site-url.
--- Workaround for https://github.com/quarto-dev/quarto-cli/issues/13029
--- where project-level metadata (website/book) is not available in the
--- document Meta passed to Lua filters.
--- Returns a (value, source) pair so the caller can warn on a parse-level
--- fallback distinct from a missing file.
--- @return string|nil value The site-url value, or nil if unavailable
--- @return "missing"|"unreadable"|"empty"|"invalid-json"|"no-metadata"|"ok"|nil source Why the value is nil (when applicable)
local function get_site_url_from_execute_info()
  local path = os.getenv('QUARTO_EXECUTE_INFO')
  if not path then return nil, 'missing' end

  local file = io.open(path, 'r')
  if not file then return nil, 'unreadable' end

  local content = file:read('*a')
  file:close()

  if not content or content == '' then return nil, 'empty' end

  local ok, info = pcall(quarto.json.decode, content)
  if not ok or not info then return nil, 'invalid-json' end

  local format_meta = info['format'] and info['format']['metadata']
  if not format_meta then return nil, 'no-metadata' end

  if format_meta['website'] and format_meta['website']['site-url'] then
    return format_meta['website']['site-url'], 'ok'
  elseif format_meta['book'] and format_meta['book']['site-url'] then
    return format_meta['book']['site-url'], 'ok'
  end

  return nil, 'no-metadata'
end

--- Read site-url from document metadata as a fallback.
--- Tries website.site-url, then book.site-url.
--- @param meta table The document metadata table
--- @return string|nil The site-url value, or nil if not found
local function get_site_url_from_meta(meta)
  local website = meta['website']
  if website and website['site-url'] then
    return pandoc.utils.stringify(website['site-url'])
  end

  local book = meta['book']
  if book and book['site-url'] then
    return pandoc.utils.stringify(book['site-url'])
  end

  return nil
end

--- Check whether a link target is a relative cross-page link.
--- Returns true for targets that point to .html or .qmd files
--- without an absolute URI scheme.
--- The `.qmd`/`.html` match is anchored to end-of-path (just before an
--- optional `#fragment` or `?query`, or at end-of-string) so a target such
--- as `foo.qmd.backup` is not mistaken for a `.qmd` cross-page link.
--- @param target string The link target URL
--- @return boolean True if the target is a relative page link
local function is_relative_page_link(target)
  if not target or target == '' then return false end
  if target:match('^#') then return false end
  if target:match('^%a[%a%d+%-%.]*:') then return false end
  if target:match('^//') then return false end
  -- A path segment ending in `.qmd` or `.html`, optionally followed by `#`
  -- or `?`, and otherwise at end-of-string. The trailing alternation guards
  -- against suffixes such as `.qmd.backup` matching mid-path.
  if target:match('%.html$') or target:match('%.html[#?]') then return true end
  if target:match('%.qmd$') or target:match('%.qmd[#?]') then return true end
  return false
end

--- Rewrite a relative page link target to an absolute URL.
--- Normalises .qmd extensions to .html, strips leading ./ and /, and
--- prepends the site-url.
--- @param target string The original relative link target
--- @param base_url string The site-url to prepend
--- @return string The rewritten absolute URL
local function rewrite_target(target, base_url)
  local rewritten = target:gsub('%.qmd([#?])', '.html%1'):gsub('%.qmd$', '.html')
  rewritten = rewritten:gsub('^%./', ''):gsub('^/+', '')
  local separator = base_url:match('/$') and '' or '/'
  return base_url .. separator .. rewritten
end

-- ============================================================================
-- FILTER EXPORT
-- ============================================================================

return {
  {
    --- Resolve site-url from project metadata.
    --- Skips entirely for plain HTML, html-based format extensions, and epub
    --- where cross-page links already work, and when the filter is disabled.
    --- HTML slide formats are processed like other non-HTML formats.
    --- @param meta table The document metadata table
    --- @return nil
    Meta = function(meta)
      -- Reset per-document state so a previous render in the same process
      -- does not leak its site-url or extra-slide-formats into this one.
      site_url = nil
      extra_slide_formats = read_extra_slide_formats(meta)

      if is_disabled(meta) then return nil end
      if quarto.doc.is_format('html') and not is_html_slides() then return nil end

      local execute_info_url, source = get_site_url_from_execute_info()
      if execute_info_url then
        site_url = execute_info_url
      else
        if source == 'invalid-json' or source == 'unreadable' then
          log.log_warning(
            EXTENSION_NAME,
            "Could not parse QUARTO_EXECUTE_INFO (" .. source ..
              "); falling back to document metadata for site-url."
          )
        end
        site_url = get_site_url_from_meta(meta)
      end

      if not site_url then
        log.log_warning(
          EXTENSION_NAME,
          "site-url not found in project metadata; links left unchanged. " ..
            "Set 'site-url' under 'website' or 'book' in '_quarto.yml' (project config), " ..
            "not in the document front matter."
        )
      end

      return nil
    end
  },
  {
    --- Rewrite relative cross-page links to absolute URLs.
    --- @param el pandoc.Link The link element
    --- @return pandoc.Link|nil The rewritten link, or nil to leave unchanged
    Link = function(el)
      if not site_url then return nil end
      if not is_relative_page_link(el.target) then return nil end

      el.target = rewrite_target(el.target, site_url)
      return el
    end
  }
}
