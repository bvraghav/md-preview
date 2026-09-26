// dropdown.js — on todo.html: the navbar "More" menu.
window.addEventListener('load', function () {
  function report(r) {
    var p = document.createElement('pre'); p.id = 'probe';
    p.textContent = Object.keys(r).map(function (k) { return k + '=' + String(r[k]).replace(/\s+/g, ' ').trim(); }).join('\n');
    document.body.appendChild(p);
  }
  var r = {}, more = document.querySelector('.site-more'), sum = more.querySelector('summary'),
      menu = more.querySelector('.site-menu'), links = menu.querySelectorAll('a');
  r.more_current = more.classList.contains('site-current');
  r.aria_current = (menu.querySelector('[aria-current=page]') || {}).textContent;
  sum.click(); r.opens = more.open;
  document.querySelector('main p').click(); r.outside_click_closes = !more.open;
  sum.click();
  more.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
  r.escape_closes = !more.open;
  r.escape_refocuses = document.activeElement === sum;
  sum.click(); links[0].focus();
  more.dispatchEvent(new FocusEvent('focusout', { relatedTarget: document.querySelector('.site-ext'), bubbles: true }));
  r.focus_leaving_closes = !more.open;
  sum.click(); links[0].focus();
  more.dispatchEvent(new FocusEvent('focusout', { relatedTarget: links[1], bubbles: true }));
  r.focus_within_stays = more.open;
  more.open = false;

  // Whether the flip is needed depends on where "More" lands, which depends
  // on fonts and wrapping. So check that it flips exactly when the
  // right-aligned menu would overflow the left edge, and then force a case
  // that needs it by moving "More" to the start of the nav.
  function inViewport() {
    var b = menu.getBoundingClientRect();
    return b.left >= 0 && b.right <= document.documentElement.clientWidth;
  }
  function needsFlip() {
    return more.getBoundingClientRect().right - menu.offsetWidth < 8;
  }
  var needed = needsFlip();
  sum.click();
  setTimeout(function () {  // the flip happens on the async 'toggle' event
    r.menu_in_viewport = inViewport();
    r.flip_correct = menu.classList.contains('site-menu-left') === needed;
    more.open = false;
    more.style.order = '-1';
    setTimeout(function () {
      sum.click();
      setTimeout(function () {
        r.forced_flipped = menu.classList.contains('site-menu-left');
        r.forced_in_viewport = inViewport();
        report(r);
      }, 150);
    }, 50);
  }, 150);
});
