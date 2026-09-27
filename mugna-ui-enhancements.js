/* Mugna UI enhancements
 * Loaded after the main application script.
 * - Caps page/card spacing at 1cm.
 * - Restores POS milk substitution and cup upsize controls.
 * - Organizes self-serve POS items by category.
 */
(() => {
  'use strict';

  const oneCm = '1cm';
  const style = document.createElement('style');
  style.textContent = `
    /* Keep all primary app spacing within the requested 1cm maximum. */
    .main { padding: ${oneCm} !important; }
    .card, .group-section, .group, .section-head { margin-bottom: ${oneCm} !important; }
    .kiosk-body { padding: ${oneCm} !important; gap: ${oneCm} !important; }
    .kiosk-menu-wrap { padding-right: ${oneCm} !important; }
    .kiosk-category-title { margin: 0 0 8px !important; }
    .kiosk-category { margin-bottom: ${oneCm} !important; }
    .pos-modifiers { display:flex; gap:6px; flex-wrap:wrap; margin:2px 0 6px 30px; }
    .pos-modifiers .input { width:auto; min-width:125px; padding:4px 8px; font-size:12.5px; }
    @media(max-width:880px) { .main { padding: 8px !important; } }
  `;
  document.head.appendChild(style);

  const get = (s, r = document) => r.querySelector(s);
  const make = (tag, attrs = {}, ...children) => {
    const n = document.createElement(tag);
    Object.entries(attrs).forEach(([k, v]) => {
      if (k === 'class') n.className = v;
      else if (k === 'text') n.textContent = v;
      else if (k === 'style') Object.assign(n.style, v);
      else if (k.startsWith('on')) n.addEventListener(k.slice(2), v);
      else n.setAttribute(k, v);
    });
    children.flat().filter(Boolean).forEach(c => n.append(c.nodeType ? c : document.createTextNode(c)));
    return n;
  };

  function ingredients() {
    return (window.State?.data?.ingredients || []);
  }
  function menuMap() {
    return new Map((window.State?.data?.menu || []).map(x => [x.id, x]));
  }
  function isMilk(x) { return !!x && /milk/i.test(x.name || ''); }
  function isCup(x) { return !!x && /cup|oz|size/i.test(x.name || ''); }
  function recipeLine(item, predicate) {
    const map = menuMap();
    return (item.recipe || []).find(r => predicate(map.get(r.ingredient_id)));
  }
  function modifierRows(item, line) {
    const all = ingredients();
    const milkLine = recipeLine(item, isMilk);
    const cupLine = recipeLine(item, isCup);
    if (!milkLine && !cupLine) return null;

    const row = make('div', { class: 'pos-modifiers' });
    if (milkLine) {
      const select = make('select', { class: 'input', 'aria-label': 'Milk choice' });
      const base = all.find(x => x.id === milkLine.ingredient_id);
      select.append(make('option', { value: '' }, `${base?.name || 'Default milk'} (default)`));
      all.filter(isMilk).forEach(x => {
        if (x.id !== milkLine.ingredient_id) {
          const up = Number(x.modifier_price || 0);
          select.append(make('option', { value: x.id }, `${x.name}${up ? ` (+₱${up.toFixed(2)})` : ''}`));
        }
      });
      select.addEventListener('change', () => {
        line.milkSub = select.value || null;
        if (typeof window.drawCart === 'function') window.drawCart();
      });
      select.value = line.milkSub || '';
      row.append(select);
    }
    if (cupLine) {
      const select = make('select', { class: 'input', 'aria-label': 'Cup size' });
      const base = all.find(x => x.id === cupLine.ingredient_id);
      select.append(make('option', { value: '' }, `${base?.name || 'Default size'} (default)`));
      all.filter(isCup).forEach(x => {
        if (x.id !== cupLine.ingredient_id) {
          const up = Number(x.modifier_price || 0);
          select.append(make('option', { value: x.id }, `${x.name}${up ? ` (+₱${up.toFixed(2)})` : ''}`));
        }
      });
      select.addEventListener('change', () => {
        line.cupSub = select.value || null;
        if (typeof window.drawCart === 'function') window.drawCart();
      });
      select.value = line.cupSub || '';
      row.append(select);
    }
    return row;
  }

  // The main POS renderer in the supplied app can call this helper while
  // building each cart line. It is also exposed for future POS renderers.
  window.renderPosModifiers = modifierRows;

  function groupedKioskMenu() {
    const items = (window.State?.data?.menu || []).filter(x => x.active !== false);
    const groups = new Map();
    items.forEach(item => {
      const key = item.category || 'Other';
      if (!groups.has(key)) groups.set(key, []);
      groups.get(key).push(item);
    });
    return groups;
  }

  // Replace the kiosk menu renderer when the app has already created its
  // kiosk overlay. This preserves the existing cart and checkout behavior.
  window.renderCategorizedKioskMenu = function renderCategorizedKioskMenu(onAdd) {
    const root = get('#kioskMenuGrid');
    if (!root) return;
    root.innerHTML = '';
    groupedKioskMenu().forEach((items, category) => {
      const section = make('section', { class: 'kiosk-category' });
      section.append(make('h2', { class: 'kiosk-category-title' }, category));
      const grid = make('div', { class: 'menu-cards' });
      items.forEach(item => {
        const card = make('button', { class: 'prod', type: 'button', onClick: () => onAdd(item) },
          make('div', { class: 'ph', style: item.photo_url ? { backgroundImage: `url("${item.photo_url}")` } : {} }, item.photo_url ? '' : '☕'),
          make('div', { class: 'pd' },
            make('div', { class: 'pn' }, item.name),
            make('div', { class: 'pp' }, `₱${Number(item.price || 0).toFixed(2) })`)
          )
        );
        grid.append(card);
      });
      section.append(grid);
      root.append(section);
    });
  };

  // If the original function exists, wrap it so its menu gets grouped after
  // the overlay opens. The wrapper intentionally leaves the existing cart
  // and payment logic untouched.
  if (typeof window.openCustomerKiosk === 'function' && !window.openCustomerKiosk.__mugnaWrapped) {
    const original = window.openCustomerKiosk;
    const wrapped = function (...args) {
      const result = original.apply(this, args);
      setTimeout(() => {
        if (typeof window.addToCart === 'function') {
          window.renderCategorizedKioskMenu(item => window.addToCart(item));
        }
      }, 0);
      return result;
    };
    wrapped.__mugnaWrapped = true;
    window.openCustomerKiosk = wrapped;
  }
})();
