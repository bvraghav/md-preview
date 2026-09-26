-- links.lua — rewrite repository-relative links for the published site.
--
--   README.md#setup    -> index.html#setup      (pages published on the site)
--   bin/md-preview     -> <repo>/blob/<ref>/bin/md-preview   (everything else)
--
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
}

local stringify = pandoc.utils.stringify

local function rewrite(target, repo, ref)
  -- absolute URLs (scheme:), protocol-relative, and same-page anchors
  if target:match('^%a[%w+.-]*:') or target:match('^//') or target:match('^#') then
    return nil
  end
  local path, frag = target:match('^([^#]*)(.*)$')
  path = path:gsub('^%./', '')
  if pages[path] then return pages[path] .. frag end
  if repo and path ~= '' then
    return repo .. '/blob/' .. ref .. '/' .. path .. frag
  end
end

function Pandoc(doc)
  local repo = doc.meta['md-preview-site-repo'] and stringify(doc.meta['md-preview-site-repo'])
  local ref = doc.meta['md-preview-site-ref'] and stringify(doc.meta['md-preview-site-ref']) or 'main'
  return doc:walk {
    Link = function(link)
      local new = rewrite(link.target, repo, ref)
      if new then
        link.target = new
        return link
      end
    end,
  }
end
