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
  sum.click();
  setTimeout(function () {  // the flip happens on the async 'toggle' event
    var b = menu.getBoundingClientRect();
    r.menu_in_viewport = b.left >= 0 && b.right <= document.documentElement.clientWidth;
    r.flipped = menu.classList.contains('site-menu-left');
    report(r);
  }, 150);
});
