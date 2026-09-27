-- links.lua — the website's pandoc filter, run before md-preview's own.
--
-- The site is a folder build of site/_build/src, where every page is staged
-- as <page>.md (see site/pages.yaml and site/Makefile). For each page this:
--   * maps links between repository files to site pages, resolved against
--     the page's real location (emacs/INSTALL.md links ../INSTALL.md):
--       README.md#setup  -> index.html#setup
--       bin/md-preview   -> <repo>/blob/<ref>/bin/md-preview   (not a page)
--   * sets the <title> and the automatic TOC from pages.yaml
--   * adds the footer (source file, commit) and the "View source" link
--
-- Metadata: md-preview-site (pages.yaml, via --metadata-file),
-- md-preview-site-repo, md-preview-site-ref, md-preview-site-version, and
-- md-preview-page (set by md-preview for each page of a folder build).
-- Images are left alone; staged next to the pages, the build copies them.

local stringify = pandoc.utils.stringify

local function str(v) return v ~= nil and stringify(v) or nil end
local function esc(s) return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('"', '&quot;')) end

-- "emacs" + "../INSTALL.md" -> "INSTALL.md"
local function resolve(dir, path)
  local parts = {}
  local joined = (dir ~= '' and dir ~= '.') and (dir .. '/' .. path) or path
  for seg in joined:gmatch('[^/]+') do
    if seg == '..' then table.remove(parts)
    elseif seg ~= '.' then table.insert(parts, seg) end
  end
  return table.concat(parts, '/')
end

local function rewrite(target, srcdir, by_source, repo, ref)
  -- absolute URLs (scheme:), protocol-relative, same-page anchors, site pages
  if target:match('^%a[%w+.-]*:') or target:match('^//') or target:match('^#') then return nil end
  local path, frag = target:match('^([^#]*)(.*)$')
  if path == '' or path:match('%.html$') then return nil end
  local real = resolve(srcdir, path)
  if by_source[real] then return by_source[real] .. '.html' .. frag end
  if repo then return repo .. '/blob/' .. ref .. '/' .. real .. frag end
end

function Pandoc(doc)
  local meta = doc.meta
  local site = meta['md-preview-site']
  local staged = str(meta['md-preview-page'])
  if not site or not staged then return nil end

  local by_page, by_source = {}, {}
  for _, p in ipairs(site.pages) do
    local page, source = str(p.page), str(p.source)
    by_page[page] = p
    if not p.generated then by_source[source] = page end
  end
  local name = staged:gsub('%.md$', '')
  local entry = by_page[name]
  if not entry then return nil end

  local source = str(entry.source)
  local srcdir = source:match('^(.*)/[^/]*$') or '.'
  local repo = str(meta['md-preview-site-repo'])
  local ref = str(meta['md-preview-site-ref']) or 'main'
  local version = str(meta['md-preview-site-version']) or ''

  doc = doc:walk {
    Link = function(link)
      local new = rewrite(link.target, srcdir, by_source, repo, ref)
      if new then link.target = new; return link end
    end,
  }

  if entry.title then doc.meta.pagetitle = str(entry.title) end
  if entry.toc == false then doc.meta['md-preview-toc'] = false end
  if entry['source-link'] then
    doc.meta['md-preview-before-html'] = pandoc.MetaBlocks { pandoc.RawBlock('html', string.format(
      '<p class="site-source-link"><a href="%s.html">View source</a></p>', esc(str(entry['source-link'])))) }
  end
  if repo then
    doc.blocks:insert(pandoc.RawBlock('html', string.format(
      '<footer class="site-footer">Rendered by md-preview %s from '
        .. '<a href="%s/blob/%s/%s"><code>%s</code></a> at <a href="%s/commit/%s"><code>%s</code></a>.</footer>',
      esc(version), esc(repo), esc(ref), esc(source), esc(source), esc(repo), esc(ref), esc(ref:sub(1, 7)))))
  end
  return doc
end
