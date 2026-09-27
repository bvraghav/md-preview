-- md-preview.lua — pandoc Lua filter used by md-preview.
--
--  * ```mermaid fences  -> <pre class="mermaid"> for mermaid.js (client side)
--  * ```math fences     -> display math (GitHub style)
--  * YAML frontmatter   -> collapsible table above the title block
--  * pagetitle fallback -> file name, so untitled documents do not warn
--  * table of contents  -> shown when the page has enough headings
--
-- Metadata read (normally set by the md-preview script via -M):
--   md-preview-file         file name, used as fallback page title
--   md-preview-frontmatter  open | closed | hide   (default: closed)
--   md-preview-toc          true | false; unset = automatic (3+ headings)
-- Metadata written:
--   md-preview-has-mermaid        true when the document contains a mermaid block
--   md-preview-tree-html          folder mode: the file tree <nav>
--   md-preview-frontmatter-html   the rendered frontmatter <details> block
--   md-preview-toc-show           true when the template should show the TOC

local stringify = pandoc.utils.stringify

local has_mermaid = false

local function html_escape(s)
  return (s:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))
end

local function has_class(el, cls)
  for _, c in ipairs(el.classes) do
    if c == cls then return true end
  end
  return false
end

local function CodeBlock(cb)
  if has_class(cb, 'mermaid') then
    has_mermaid = true
    local id = cb.identifier ~= '' and (' id="' .. html_escape(cb.identifier) .. '"') or ''
    return pandoc.RawBlock('html',
      '<pre class="mermaid"' .. id .. '>' .. html_escape(cb.text) .. '</pre>')
  end
  if has_class(cb, 'math') then
    return pandoc.Para { pandoc.Math('DisplayMath', cb.text) }
  end
end

-- ---------------------------------------------------------- frontmatter ---

-- Keys that pandoc or md-preview consume themselves; not worth showing.
local hidden = {
  ['header-includes'] = true, ['include-before'] = true,
  ['include-after'] = true, ['pagetitle'] = true,
}

-- Emit math as KaTeX spans so the page's KaTeX loader renders it too.
local write_opts = { html_math_method = { method = 'katex' } }

local function to_html(v)
  local t = pandoc.utils.type(v)
  if t == 'Inlines' then
    return pandoc.write(pandoc.Pandoc { pandoc.Plain(v) }, 'html', write_opts)
  elseif t == 'Blocks' then
    return pandoc.write(pandoc.Pandoc(v), 'html', write_opts)
  elseif t == 'List' then
    local items = {}
    for _, x in ipairs(v) do items[#items + 1] = '<li>' .. to_html(x) .. '</li>' end
    return '<ul>' .. table.concat(items) .. '</ul>'
  elseif t == 'table' then
    local keys = {}
    for k in pairs(v) do keys[#keys + 1] = k end
    table.sort(keys)
    local rows = {}
    for _, k in ipairs(keys) do
      rows[#rows + 1] = '<tr><th>' .. html_escape(k) .. '</th><td>'
        .. to_html(v[k]) .. '</td></tr>'
    end
    return '<table>' .. table.concat(rows) .. '</table>'
  elseif t == 'boolean' then
    return '<code>' .. tostring(v) .. '</code>'
  else
    return html_escape(stringify(v))
  end
end

local function frontmatter_block(meta, mode)
  local shown = {}
  for k, v in pairs(meta) do
    if not hidden[k] and not k:match('^md%-preview') then shown[k] = v end
  end
  if next(shown) == nil then return nil end
  local n = 0
  for _ in pairs(shown) do n = n + 1 end
  return pandoc.RawBlock('html', string.format(
    '<details class="mdp-frontmatter"%s><summary>frontmatter · %d key%s</summary>%s</details>',
    mode == 'open' and ' open' or '', n, n == 1 and '' or 's', to_html(shown)))
end

-- Headings that pandoc's --toc lists (default --toc-depth is 3).
local TOC_MIN_HEADINGS = 3

local function toc_show(doc)
  local setting = doc.meta['md-preview-toc']
  if setting ~= nil then
    local v = pandoc.utils.type(setting) == 'boolean' and setting or stringify(setting)
    if v == false or v == 'false' then return false end
    if v == true or v == 'true' then return true end
  end
  local n = 0
  doc.blocks:walk {
    Header = function(h)
      if h.level <= 3 and not h.classes:includes('unlisted') then n = n + 1 end
    end,
  }
  return n >= TOC_MIN_HEADINGS
end

-- ------------------------------------------------------------ folder mode ---
--
-- Set by `md-preview build DIR` / `serve DIR` for each page:
--   md-preview-page       this page's source, relative to the folder
--                         ("a/b.md"), or "a/" for a generated listing
--   md-preview-tree-file  the folder's tree (see folder_tree in the script):
--                         P<tab>source<tab>page, D<tab>folder<tab>index
--   md-preview-root-name  the folder's name, for the top of the tree
--   md-preview-tree       false hides the file tree (default: shown)

local function split_path(p)
  local t = {}
  for seg in p:gmatch('[^/]+') do if seg ~= '.' then t[#t + 1] = seg end end
  return t
end

-- "a/b" + "../c/d.md" -> "a/c/d.md"; nil if it leaves the folder
local function resolve(dir, path)
  local out = {}
  for _, seg in ipairs(split_path(dir .. '/' .. path)) do
    if seg == '..' then
      if #out == 0 then return nil end
      table.remove(out)
    else
      out[#out + 1] = seg
    end
  end
  return #out == 0 and '.' or table.concat(out, '/')
end

-- relative link from folder FROM to file TO (both relative to the root)
local function relpath(from, to)
  local a, b = split_path(from), split_path(to)
  local i = 1
  while i <= #a and i < #b and a[i] == b[i] do i = i + 1 end
  return ('../'):rep(#a - i + 1) .. table.concat(b, '/', i)
end

local function url_decode(s)
  return (s:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end))
end
local function url_encode(s)
  return (s:gsub('[%%%s#?"]', function(c) return string.format('%%%02X', c:byte()) end))
end

local function read_tree(path)
  local f = io.open(path, 'r')
  if not f then return nil end
  local tree = { pages = {}, dirs = {}, entries = {} }
  for line in f:lines() do
    local kind, a, b = line:match('^(%a)\t([^\t]*)\t?(.*)$')
    if kind == 'P' then tree.pages[a] = b; tree.entries[#tree.entries + 1] = { kind = 'P', src = a, page = b }
    elseif kind == 'D' then tree.dirs[a] = b; tree.entries[#tree.entries + 1] = { kind = 'D', src = a, page = b }
    end
  end
  f:close()
  return tree
end

local function parent_of(p) return p:match('^(.*)/[^/]*$') or '.' end

-- Rewrite relative links to Markdown files (and folders) in the folder to
-- the pages they become, relative to this page.
local function rewrite_links(doc, tree, pagedir)
  return doc:walk {
    Link = function(link)
      local t = link.target
      if t:match('^%a[%w+.-]*:') or t:match('^//') or t:match('^#') then return nil end
      local path, frag = t:match('^([^#?]*)(.*)$')
      if path == '' then return nil end
      local target = resolve(pagedir, url_decode(path))
      if not target then return nil end
      local page = tree.pages[target] or tree.dirs[target]
      if not page then return nil end
      link.target = url_encode(relpath(pagedir, page)) .. frag
      return link
    end,
  }
end

-- (parenthesised: gsub also returns a count, which would shift format args)
local function esc(s) return (html_escape(s):gsub('"', '&quot;')) end

-- The file tree as HTML: folders (with their index) and pages, the current
-- page marked, folders on its path open.
local function tree_html(tree, current_page, pagedir, root_name)
  local children = {}
  local function add(parent, entry)
    children[parent] = children[parent] or {}
    table.insert(children[parent], entry)
  end
  for _, e in ipairs(tree.entries) do
    if e.kind == 'D' and e.src ~= '.' then add(parent_of(e.src), e)
    elseif e.kind == 'P' and e.page ~= tree.dirs[parent_of(e.src)] then add(parent_of(e.src), e)
    end
  end
  local function sorted(list)
    table.sort(list, function(x, y)
      if x.kind ~= y.kind then return x.kind == 'D' end
      return x.src:lower() < y.src:lower()
    end)
    return list
  end
  local function href(page) return esc(url_encode(relpath(pagedir, page))) end
  local function current(page) return page == current_page and ' aria-current="page"' or '' end
  local function render(dir)
    local items = {}
    for _, e in ipairs(sorted(children[dir] or {})) do
      local name = esc(e.src:match('[^/]+$'))
      if e.kind == 'D' then
        local open = (current_page:sub(1, #e.src + 1) == e.src .. '/') and ' open' or ''
        items[#items + 1] = string.format(
          '<li class="mdp-tree-dir"><details%s><summary><a href="%s"%s>%s/</a></summary>%s</details></li>',
          open, href(e.page), current(e.page), name, render(e.src))
      else
        items[#items + 1] = string.format('<li><a href="%s"%s>%s</a></li>',
          href(e.page), current(e.page), (name:gsub('%.[^.]+$', '')))
      end
    end
    return #items > 0 and ('<ul>' .. table.concat(items) .. '</ul>') or ''
  end
  return string.format(
    '<nav class="mdp-tree" aria-label="Files"><details open><summary>Files</summary>'
      .. '<div class="mdp-tree-body"><a class="mdp-tree-root" href="%s"%s>%s/</a>%s</div></details></nav>',
    href(tree.dirs['.']), current(tree.dirs['.']), esc(root_name), render('.'))
end

local function folder_mode(doc)
  local meta = doc.meta
  local page = meta['md-preview-page'] and stringify(meta['md-preview-page'])
  local tree_file = meta['md-preview-tree-file'] and stringify(meta['md-preview-tree-file'])
  if not page or not tree_file then return doc end
  local tree = read_tree(tree_file)
  if not tree then return doc end
  local pagedir = page:match('/$') and page:gsub('/$', '') or parent_of(page)
  if pagedir == '' then pagedir = '.' end
  local current_page = page:match('/$') and tree.dirs[pagedir] or tree.pages[page]
  doc = rewrite_links(doc, tree, pagedir)
  local show = meta['md-preview-tree']
  if not (show == false or (show ~= nil and stringify(show) == 'false')) then
    local root_name = meta['md-preview-root-name'] and stringify(meta['md-preview-root-name']) or '.'
    doc.meta['md-preview-tree-html'] = pandoc.MetaBlocks {
      pandoc.RawBlock('html', tree_html(tree, current_page or '', pagedir, root_name)) }
  end
  return doc
end

-- The first level-1 heading, as plain text, if any.
local function first_h1(doc)
  for _, b in ipairs(doc.blocks) do
    if b.t == 'Header' and b.level == 1 then return stringify(b.content) end
  end
end

local function Pandoc(doc)
  if not FORMAT:match('html') then return nil end
  doc = folder_mode(doc)
  local meta = doc.meta

  if not meta.title and not meta.pagetitle then
    local h1 = first_h1(doc)
    if h1 and h1 ~= '' then meta.pagetitle = h1
    elseif meta['md-preview-file'] then meta.pagetitle = meta['md-preview-file'] end
  end

  -- Handed to the template as a variable so it can sit above the title block.
  local mode = meta['md-preview-frontmatter'] and stringify(meta['md-preview-frontmatter']) or 'closed'
  if mode ~= 'hide' then
    local block = frontmatter_block(meta, mode)
    if block then meta['md-preview-frontmatter-html'] = pandoc.MetaBlocks { block } end
  end

  if has_mermaid then meta['md-preview-has-mermaid'] = true end
  if toc_show(doc) then meta['md-preview-toc-show'] = true end
  doc.meta = meta
  return doc
end

return {
  { CodeBlock = function(cb) if FORMAT:match('html') then return CodeBlock(cb) end end },
  { Pandoc = Pandoc },
}
