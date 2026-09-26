-- links.lua — rewrite repository-relative links for the published site.
--
--   README.md#setup    -> index.html#setup      (pages published on the site)
--   bin/md-preview     -> <repo>/blob/<ref>/bin/md-preview   (everything else)
--
-- Links are resolved against the source file's directory (metadata
-- md-preview-site-srcdir, e.g. "emacs" for emacs/INSTALL.md) first.
-- Images are left alone; the site Makefile copies the ones the pages use.
-- Reads metadata: md-preview-site-repo (repository URL) and md-preview-site-ref
-- (commit or branch); the md-preview- prefix keeps them out of the frontmatter table.

-- Keep in sync with the page rules in site/Makefile.
local pages = {
  ['README.md']      = 'index.html',
  ['test-sample.md'] = 'demo.html',
  ['CHANGELOG.md']   = 'changelog.html',
  ['LICENSE']        = 'license.html',
  ['MANIFEST.md']    = 'manifest.html',
  ['REFERENCE.md']   = 'reference.html',
  ['TODO.md']        = 'todo.html',
  ['INSTALL.md']     = 'install.html',
  ['CONTRIBUTING.md'] = 'contributing.html',
  ['emacs/INSTALL.md'] = 'emacs.html',
}

local stringify = pandoc.utils.stringify

-- "emacs" + "../INSTALL.md" -> "INSTALL.md"
local function resolve(srcdir, path)
  local parts = {}
  local joined = (srcdir ~= '' and (srcdir .. '/') or '') .. path
  for seg in joined:gmatch('[^/]+') do
    if seg == '..' then table.remove(parts)
    elseif seg ~= '.' then table.insert(parts, seg) end
  end
  return table.concat(parts, '/')
end

local function rewrite(target, repo, ref, srcdir)
  -- absolute URLs (scheme:), protocol-relative, and same-page anchors
  if target:match('^%a[%w+.-]*:') or target:match('^//') or target:match('^#') then
    return nil
  end
  local path, frag = target:match('^([^#]*)(.*)$')
  if path == '' then return nil end
  path = resolve(srcdir, path)
  if pages[path] then return pages[path] .. frag end
  -- already a site page
  if path:match('%.html$') then return nil end
  if repo then
    return repo .. '/blob/' .. ref .. '/' .. path .. frag
  end
end

function Pandoc(doc)
  local repo = doc.meta['md-preview-site-repo'] and stringify(doc.meta['md-preview-site-repo'])
  local ref = doc.meta['md-preview-site-ref'] and stringify(doc.meta['md-preview-site-ref']) or 'main'
  local srcdir = doc.meta['md-preview-site-srcdir'] and stringify(doc.meta['md-preview-site-srcdir']) or ''
  return doc:walk {
    Link = function(link)
      local new = rewrite(link.target, repo, ref, srcdir)
      if new then
        link.target = new
        return link
      end
    end,
  }
end
