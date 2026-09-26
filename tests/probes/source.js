// source.js — on demo-source.html: line numbers and the copy button.
window.addEventListener('load', function () {
  function report(r) {
    var p = document.createElement('pre'); p.id = 'probe';
    p.textContent = Object.keys(r).map(function (k) { return k + '=' + String(r[k]).replace(/\s+/g, ' ').trim(); }).join('\n');
    document.body.appendChild(p);
  }
  var a = document.querySelector('pre.numberSource code > span > a:first-child');
  var before = getComputedStyle(a, '::before');
  var pre = document.querySelector('pre.numberSource');
  var num = a.getBoundingClientRect(), box = pre.parentElement.getBoundingClientRect();
  report({
    line_number_content: before.content,
    line_number_underlined: before.textDecorationLine !== 'none',
    line_number_visible: num.left >= box.left - 1,
    copy_buttons: document.querySelectorAll('.mdp-copy').length,
    lines: document.querySelectorAll('pre.numberSource code > span').length
  });
});
