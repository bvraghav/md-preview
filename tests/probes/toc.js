// toc.js — on demo.html: current-section highlight and remembered toggle.
window.addEventListener('load', function () {
  function report(r) {
    var p = document.createElement('pre'); p.id = 'probe';
    p.textContent = Object.keys(r).map(function (k) { return k + '=' + String(r[k]).replace(/\s+/g, ' ').trim(); }).join('\n');
    document.body.appendChild(p);
  }
  var r = {}, toc = document.querySelector('.mdp-toc'), box = toc.querySelector('details');
  // Opened as demo.html#entity-relationship (see test-browser.sh). Headless
  // Chromium runs no animation frames or scroll events after load, so this
  // tests the deep-link path: md-preview re-scrolls to the fragment and
  // updates the highlight once mermaid has drawn the diagrams above it.
  var target = document.getElementById('entity-relationship');
  var tries = 0;
  (function wait() {
    if (document.documentElement.dataset.mermaid !== 'done' && ++tries <= 100) return setTimeout(wait, 100);
    setTimeout(check, 300);
  })();
  function check() {
    var act = toc.querySelector('.mdp-active');
    r.target_top = Math.round(target.getBoundingClientRect().top);
    r.active = act ? act.textContent : 'none';
    r.active_count = toc.querySelectorAll('.mdp-active').length;
    var was = box.open;
    box.open = !was;
    setTimeout(function () {
      var saved = [];
      for (var i = 0; i < localStorage.length; i++) {
        var k = localStorage.key(i);
        if (k.indexOf('md-preview-toc-open:') === 0) saved.push(k + ':' + localStorage.getItem(k));
      }
      r.saved = saved.join(',');
      r.saved_matches = saved.length === 1 && saved[0].slice(-1) === (was ? '0' : '1');
      report(r);
    }, 150);
  }
});
