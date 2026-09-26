// render.js — on demo.html: math, diagrams, image, and the enhancements.
(function () {
  function report(r) {
    var p = document.createElement('pre'); p.id = 'probe';
    p.textContent = Object.keys(r).map(function (k) { return k + '=' + String(r[k]).replace(/\s+/g, ' ').trim(); }).join('\n');
    document.body.appendChild(p);
  }
  function run() {
    var ids = Array.prototype.map.call(document.querySelectorAll('pre.mermaid svg'), function (s) { return s.id; });
    var img = document.querySelector('img[src$="badge.svg"]');
    var toc = document.querySelector('.mdp-toc');
    report({
      katex: document.querySelectorAll('.katex').length,
      katex_errors: document.querySelectorAll('.katex-error').length,
      unrendered_math: Array.prototype.filter.call(document.querySelectorAll('span.math'), function (s) { return !s.querySelector('.katex, .katex-error'); }).length,
      mermaid_svgs: ids.length,
      mermaid_unique_ids: new Set(ids).size,
      mermaid_zero_height: Array.prototype.filter.call(document.querySelectorAll('pre.mermaid svg'), function (s) { return s.getBoundingClientRect().height < 20; }).length,
      image_loaded: !!(img && img.complete && img.naturalWidth > 0),
      anchors: document.querySelectorAll('.mdp-anchor').length,
      headings: document.querySelectorAll('main :is(h1,h2,h3,h4,h5,h6)[id]').length,
      copy_buttons: document.querySelectorAll('.mdp-copy').length,
      code_blocks: document.querySelectorAll('main pre > code').length,
      toc_position: toc ? getComputedStyle(toc).position : 'none',
      toc_open: toc ? toc.querySelector('details').open : 'none'
    });
  }
  // Wait for mermaid, which renders asynchronously after load.
  var tries = 0;
  (function wait() {
    if (document.documentElement.dataset.mermaid === 'done' || ++tries > 100) return setTimeout(run, 200);
    setTimeout(wait, 100);
  })();
})();
