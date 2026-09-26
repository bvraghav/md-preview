-- md-preview.lua — pandoc Lua filter used by md-preview.
--
--  * ```mermaid fences  -> <pre class="mermaid"> for mermaid.js (client side)
--  * ```math fences     -> display math (GitHub style)
--  * YAML frontmatter   -> collapsible table above the title block
--  * pagetitle fallback -> file name, so untitled documents do not warn
--
-- Metadata read (normally set by the md-preview script via -M):
--   md-preview-file         file name, used as fallback page title
--   md-preview-frontmatter  open | closed | hide   (default: closed)
-- Metadata written:
--   md-preview-has-mermaid        true when the document contains a mermaid block
--   md-preview-frontmatter-html   the rendered frontmatter <details> block

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

local function Pandoc(doc)
  local meta = doc.meta
  if not FORMAT:match('html') then return nil end

  if not meta.title and not meta.pagetitle and meta['md-preview-file'] then
    meta.pagetitle = meta['md-preview-file']
  end

  -- Handed to the template as a variable so it can sit above the title block.
  local mode = meta['md-preview-frontmatter'] and stringify(meta['md-preview-frontmatter']) or 'closed'
  if mode ~= 'hide' then
    local block = frontmatter_block(meta, mode)
    if block then meta['md-preview-frontmatter-html'] = pandoc.MetaBlocks { block } end
  end

  if has_mermaid then meta['md-preview-has-mermaid'] = true end
  doc.meta = meta
  return doc
end

return {
  { CodeBlock = function(cb) if FORMAT:match('html') then return CodeBlock(cb) end end },
  { Pandoc = Pandoc },
}
