// md-preview.js — progressive enhancements for md-preview pages.
//
// Pages are complete without JavaScript; this only adds conveniences:
//   * heading anchors   "#" link next to each section heading
//   * copy buttons      on code blocks
//   * table of contents remembers hide/show, highlights the current section
//
// Loaded with `defer`, so the DOM is ready when it runs.

(function () {
  'use strict';

  var main = document.querySelector('main.markdown-body');
  if (!main) return;

  // localStorage can be missing or throw (private windows, file://).
  function load(key) {
    try { return localStorage.getItem(key); } catch (e) { return null; }
  }
  function save(key, value) {
    try { localStorage.setItem(key, value); } catch (e) {}
  }

  // ------------------------------------------------------ heading anchors

  main.querySelectorAll('h1[id], h2[id], h3[id], h4[id], h5[id], h6[id]').forEach(function (h) {
    if (h.closest('.mdp-toc, .mdp-frontmatter, #title-block-header')) return;
    var a = document.createElement('a');
    a.className = 'mdp-anchor';
    a.href = '#' + h.id;
    a.setAttribute('aria-label', 'Link to this section');
    a.textContent = '#';
    h.appendChild(a);
  });

  // ---------------------------------------------------------- copy buttons

  function copyText(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text);
    }
    // file:// and plain http: fall back to a hidden textarea.
    return new Promise(function (resolve, reject) {
      var ta = document.createElement('textarea');
      ta.value = text;
      ta.setAttribute('readonly', '');
      ta.style.cssText = 'position:fixed;top:0;left:0;opacity:0';
      document.body.appendChild(ta);
      ta.select();
      try {
        if (document.execCommand('copy')) resolve(); else reject(new Error('copy refused'));
      } catch (e) {
        reject(e);
      } finally {
        ta.remove();
      }
    });
  }

  function flash(btn, label) {
    btn.textContent = label;
    btn.classList.add('mdp-copied');
    clearTimeout(btn.mdpTimer);
    btn.mdpTimer = setTimeout(function () {
      btn.textContent = 'Copy';
      btn.classList.remove('mdp-copied');
    }, 1500);
  }

  main.querySelectorAll('pre > code').forEach(function (code) {
    var pre = code.parentElement;
    var host = pre.closest('div.sourceCode') || pre;
    // Wrap so the button stays put while the block scrolls sideways.
    var wrap = document.createElement('div');
    wrap.className = 'mdp-copy-wrap';
    host.parentNode.insertBefore(wrap, host);
    wrap.appendChild(host);
    var btn = document.createElement('button');
    btn.type = 'button';
    btn.className = 'mdp-copy';
    btn.textContent = 'Copy';
    btn.setAttribute('aria-label', 'Copy code to clipboard');
    btn.addEventListener('click', function () {
      // textContent, not innerText: line numbers are CSS-generated either way,
      // and textContent also works inside closed <details>.
      copyText(code.textContent.replace(/\n$/, '')).then(
        function () { flash(btn, 'Copied'); },
        function () { flash(btn, 'Failed'); });
    });
    wrap.appendChild(btn);
  });

  // --------------------------------------------- sidebars: TOC, file tree

  var wide = window.matchMedia('(min-width: 1400px)');

  // Remember whether a sidebar is open, separately for the sidebar (wide)
  // and inline (narrow) layouts. With no preference: open as a sidebar,
  // closed inline so it doesn't push the content down.
  function sidebar(nav, name) {
    var box = nav.querySelector('details');
    function key() { return 'md-preview-' + name + '-open:' + (wide.matches ? 'wide' : 'narrow'); }
    function restore() {
      var saved = load(key());
      box.open = saved === null ? wide.matches : saved === '1';
    }
    restore();
    if (wide.addEventListener) wide.addEventListener('change', restore);
    box.addEventListener('toggle', function () { save(key(), box.open ? '1' : '0'); });
    return box;
  }

  // Keep LINK visible when BODY scrolls on its own.
  function reveal(body, link) {
    if (body.scrollHeight <= body.clientHeight) return;
    var lr = link.getBoundingClientRect(), br = body.getBoundingClientRect();
    if (lr.top < br.top) body.scrollTop -= br.top - lr.top + 16;
    else if (lr.bottom > br.bottom) body.scrollTop += lr.bottom - br.bottom + 16;
  }

  var tree = document.querySelector('.mdp-tree');
  if (tree) {
    var treeBox = sidebar(tree, 'tree');
    var here = tree.querySelector('[aria-current="page"]');
    if (here && treeBox.open) reveal(tree.querySelector('.mdp-tree-body'), here);
  }

  var toc = document.querySelector('.mdp-toc');
  if (!toc) return;
  var box = sidebar(toc, 'toc');
  var body = toc.querySelector('.mdp-toc-body');

  // Highlight the section being read: the last heading above the fold.
  var links = {};
  toc.querySelectorAll('a[href^="#"]').forEach(function (a) {
    links[decodeURIComponent(a.getAttribute('href').slice(1))] = a;
  });
  var heads = Array.prototype.filter.call(
    main.querySelectorAll('h1[id], h2[id], h3[id], h4[id], h5[id], h6[id]'),
    function (h) { return links[h.id]; });
  if (!heads.length) return;

  var active = null;
  function spy() {
    var current = heads[0];
    for (var i = 0; i < heads.length; i++) {
      if (heads[i].getBoundingClientRect().top < 96) current = heads[i];
      else break;
    }
    var link = links[current.id];
    if (link === active) return;
    if (active) active.classList.remove('mdp-active');
    link.classList.add('mdp-active');
    active = link;
    // Keep it visible when the sidebar list scrolls on its own.
    if (box.open) reveal(body, link);
  }
  var queued = false;
  addEventListener('scroll', function () {
    if (queued) return;
    queued = true;
    requestAnimationFrame(function () { queued = false; spy(); });
  }, { passive: true });
  addEventListener('resize', spy);
  addEventListener('load', spy);
  addEventListener('md-preview:layout', spy);   // after mermaid has rendered
  spy();
})();
