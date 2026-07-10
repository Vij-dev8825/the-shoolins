const API = '/api';

const Shop = (() => {
  function getToken() { return localStorage.getItem('shop_token'); }
  function getUser() {
    try { return JSON.parse(localStorage.getItem('shop_user') || 'null'); }
    catch { return null; }
  }
  function setSession(token, user) {
    localStorage.setItem('shop_token', token);
    localStorage.setItem('shop_user', JSON.stringify(user));
  }
  function clearSession() {
    localStorage.removeItem('shop_token');
    localStorage.removeItem('shop_user');
  }
  function isLoggedIn() { return !!getToken(); }

  async function apiFetch(path, options = {}) {
    const headers = Object.assign({ 'Content-Type': 'application/json' }, options.headers || {});
    const token = getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;
    const res = await fetch(`${API}${path}`, { ...options, headers });
    if (res.status === 401) {
      clearSession();
      updateNavAuthState();
    }
    if (res.status === 204) return null;
    const text = await res.text();
    const data = text ? JSON.parse(text) : null;
    if (!res.ok) throw new Error((data && data.error) || 'Request failed');
    return data;
  }

  function formatInr(amount) {
    return '₹' + Number(amount).toLocaleString('en-IN', { maximumFractionDigits: 0 });
  }

  function imageSrc(item) {
    if (item.imageBase64) return `data:image/jpeg;base64,${item.imageBase64}`;
    if (item.image) return `/products-assets/${item.image}`;
    return '';
  }

  function productImages(item) {
    const imgs = [imageSrc(item)];
    (item.imagesBase64 || []).forEach((b64) => imgs.push(`data:image/jpeg;base64,${b64}`));
    return imgs;
  }

  // Hover-scrub preview: moving the mouse across the thumbnail cycles through
  // the product's photos based on horizontal position, so shoppers can peek
  // at other angles without opening the product page.
  function attachHoverScrub(wrap, imgEl, images) {
    if (!images || images.length <= 1) return;

    const dots = document.createElement('div');
    dots.className = 'thumb-dots';
    images.forEach((_, i) => {
      const dot = document.createElement('span');
      dot.className = 'dot' + (i === 0 ? ' active' : '');
      dots.appendChild(dot);
    });
    wrap.appendChild(dots);

    function setIndex(i) {
      imgEl.src = images[i];
      dots.querySelectorAll('.dot').forEach((d, i2) => d.classList.toggle('active', i2 === i));
    }

    wrap.addEventListener('mousemove', (e) => {
      const rect = wrap.getBoundingClientRect();
      const fraction = (e.clientX - rect.left) / rect.width;
      const index = Math.max(0, Math.min(images.length - 1, Math.floor(fraction * images.length)));
      setIndex(index);
    });
    wrap.addEventListener('mouseleave', () => setIndex(0));
  }

  function toast(message) {
    let root = document.getElementById('toast-root');
    if (!root) {
      root = document.createElement('div');
      root.id = 'toast-root';
      document.body.appendChild(root);
    }
    const el = document.createElement('div');
    el.className = 'toast';
    el.textContent = message;
    root.appendChild(el);
    setTimeout(() => el.remove(), 2600);
  }

  let cartCountCache = 0;

  async function refreshCartCount() {
    const badge = document.getElementById('nav-cart-badge');
    if (!isLoggedIn()) {
      cartCountCache = 0;
      if (badge) badge.style.display = 'none';
      return;
    }
    try {
      const cart = await apiFetch('/cart');
      cartCountCache = (cart || []).reduce((sum, i) => sum + i.quantity, 0);
      if (badge) {
        if (cartCountCache > 0) {
          badge.textContent = cartCountCache;
          badge.style.display = 'flex';
        } else {
          badge.style.display = 'none';
        }
      }
    } catch (e) {
      // not logged in or network hiccup — leave badge hidden
    }
  }

  let lastActiveNav = undefined;

  function renderNav(active) {
    const mount = document.getElementById('shop-nav-mount');
    if (!mount) return;
    if (active !== undefined) lastActiveNav = active;
    active = lastActiveNav;
    const loggedIn = isLoggedIn();
    const navLink = (href, i18nKey, fallback, key) =>
      `<a href="${href}" data-i18n="${i18nKey}" ${active === key ? 'style="opacity:1;font-weight:600"' : ''}>${fallback}</a>`;
    const hasI18n = typeof I18N !== 'undefined';
    const currentLang = hasI18n ? I18N.getLang() : 'en';
    const langOptions = hasI18n
      ? Object.entries(I18N.LANGS).map(([code, label]) =>
          `<option value="${code}" ${code === currentLang ? 'selected' : ''}>${label}</option>`).join('')
      : '';

    mount.innerHTML = `
      <header class="shop-nav">
        <div class="nav-utility">
          <div class="nav-utility-inner">
            ${hasI18n ? `<select id="lang-select" class="lang-select">${langOptions}</select>` : ''}
            <div class="utility-icons">
              <a href="/wishlist.html" class="icon-link" title="Wishlist">&#9825;</a>
              <a href="/cart.html" class="icon-link" title="Cart">
                &#128092;
                <span class="badge" id="nav-cart-badge" style="display:none">0</span>
              </a>
              ${loggedIn
                ? `<a href="/profile.html" class="pill shine" data-i18n="navProfile">Profile</a>`
                : `<a href="/login.html" class="pill shine" data-i18n="navLogin">Login</a>`}
            </div>
          </div>
        </div>
        <div class="nav-main">
          <div class="nav-main-inner">
            <a href="/" class="brand">
              <span class="brand-logo-wrap"><img src="/media/logo.png" class="brand-logo" alt="The Shoolins" /></span>
              THE SHOOLINS
            </a>
            <nav>
              ${navLink('/', 'navHome', 'Home', 'home')}
              ${navLink('/shop.html', 'navShop', 'Shop', 'shop')}
              ${navLink('/combos.html', 'navCombos', 'Combos', 'combos')}
              ${navLink('/reviews.html', 'navReviews', 'Reviews', 'reviews')}
              ${navLink('/bulk-enquiry.html', 'navBulk', 'Bulk Enquiry', 'bulk')}
              ${navLink('/about.html', 'navAbout', 'About', 'about')}
              ${navLink('/contact.html', 'navContact', 'Contact', 'contact')}
            </nav>
          </div>
        </div>
      </header>
    `;
    refreshCartCount();
    if (hasI18n) {
      I18N.apply(mount);
      document.getElementById('lang-select').addEventListener('change', (e) => {
        I18N.setLang(e.target.value);
        window.location.reload();
      });
    }
  }

  function updateNavAuthState() { renderNav(); }

  function requireLogin(redirectMessage) {
    if (!isLoggedIn()) {
      const next = window.location.pathname + window.location.search;
      window.location.href = `/login.html?next=${encodeURIComponent(next)}`;
      return false;
    }
    return true;
  }

  // ---------- Mock payment sheet (mirrors the app's simulated Razorpay-style flow) ----------
  function showPaymentSheet(amount) {
    return new Promise((resolve) => {
      const backdrop = document.createElement('div');
      backdrop.className = 'modal-backdrop';
      const methods = [
        { key: 'upi', label: 'UPI', icon: '&#128241;' },
        { key: 'card', label: 'Credit / Debit Card', icon: '&#128179;' },
        { key: 'netbanking', label: 'Net Banking', icon: '&#127974;' },
        { key: 'wallet', label: 'Wallet', icon: '&#128176;' },
      ];
      let selected = 'upi';
      let cancellable = true;
      backdrop.addEventListener('click', (e) => {
        if (e.target === backdrop && cancellable) {
          backdrop.remove();
          resolve(false);
        }
      });

      function renderMethodStep() {
        backdrop.innerHTML = `
          <div class="modal-sheet">
            <button class="modal-close-btn" id="pay-close">&times;</button>
            <div class="modal-handle"></div>
            <h2 style="margin:0 0 4px;font-size:18px;display:flex;align-items:center;gap:8px">
              <span>&#128274;</span> Secure Checkout
            </h2>
            <p class="muted" style="margin:0 0 4px">Amount payable</p>
            <p class="serif" style="font-size:30px;font-weight:700;color:var(--gold-dark);margin:0 0 20px">${formatInr(amount)}</p>
            <div id="method-list"></div>
            <button class="btn btn-gold btn-block shine" id="pay-btn" style="margin-top:14px">Pay ${formatInr(amount)}</button>
            <button class="btn btn-outline btn-block" id="pay-cancel-btn" style="margin-top:10px">Cancel</button>
          </div>
        `;
        const list = backdrop.querySelector('#method-list');
        methods.forEach((m) => {
          const tile = document.createElement('div');
          tile.className = 'method-tile' + (selected === m.key ? ' selected' : '');
          tile.innerHTML = `<span>${m.icon}</span><span style="flex:1">${m.label}</span><span class="radio"></span>`;
          tile.addEventListener('click', () => { selected = m.key; renderMethodStep(); });
          list.appendChild(tile);
        });
        backdrop.querySelector('#pay-btn').addEventListener('click', renderProcessingStep);
        function cancel() { backdrop.remove(); resolve(false); }
        backdrop.querySelector('#pay-close').addEventListener('click', cancel);
        backdrop.querySelector('#pay-cancel-btn').addEventListener('click', cancel);
      }

      function renderProcessingStep() {
        cancellable = false;
        backdrop.innerHTML = `
          <div class="modal-sheet" style="text-align:center;padding:48px 26px">
            <div class="pay-spinner"></div>
            <p style="margin:20px 0 4px;font-weight:600">Processing your payment&hellip;</p>
            <p class="muted" style="margin:0">Please don't close this window</p>
          </div>
        `;
        setTimeout(renderSuccessStep, 1600);
      }

      function renderSuccessStep() {
        backdrop.innerHTML = `
          <div class="modal-sheet" style="text-align:center;padding:40px 26px">
            <div class="pay-success-icon">&#10003;</div>
            <p style="margin:18px 0 2px;font-weight:600;font-size:16px">Payment Successful</p>
            <p class="muted" style="margin:0">${formatInr(amount)}</p>
          </div>
        `;
        setTimeout(() => {
          backdrop.remove();
          resolve(true);
        }, 1100);
      }

      renderMethodStep();
      document.body.appendChild(backdrop);
    });
  }

  // ---------- Quick view modal (opened via the eye icon on product cards) ----------
  async function showQuickView(product) {
    const images = productImages(product);
    let index = 0;
    let quantity = 1;
    let wished = false;
    if (isLoggedIn()) {
      try {
        const items = await apiFetch('/wishlist');
        wished = items.some((i) => i.productId === product.id);
      } catch (e) { /* ignore */ }
    }

    const backdrop = document.createElement('div');
    backdrop.className = 'modal-backdrop';
    backdrop.addEventListener('click', (e) => { if (e.target === backdrop) close(); });
    function close() { backdrop.remove(); }

    function render() {
      backdrop.innerHTML = `
        <div class="modal-sheet quickview">
          <button class="modal-close-btn" id="qv-close">&times;</button>
          <div class="qv-body">
            <div class="qv-image">
              <img src="${images[index]}" alt="${product.name}" />
              ${images.length > 1 ? `<div class="gallery-dots" id="qv-dots"></div>` : ''}
            </div>
            <div class="qv-details">
              <span class="eyebrow" style="text-transform:uppercase;color:var(--gold-dark);font-size:11px;font-weight:700;letter-spacing:1.5px">${product.category}</span>
              <h2 class="serif" style="margin:6px 0 8px;font-size:23px">${product.name}</h2>
              <p class="serif" style="font-size:22px;font-weight:700;color:var(--gold-dark);margin:0 0 20px">${formatInr(product.price)}</p>
              <div class="qv-qty-row">
                <button class="qv-qty-btn" id="qv-qty-minus">&minus;</button>
                <span class="qv-qty-value" id="qv-qty-value">${quantity}</span>
                <button class="qv-qty-btn" id="qv-qty-plus">+</button>
              </div>
              <div style="display:flex;gap:10px;margin-top:auto">
                <button class="btn btn-gold shine" id="qv-add-btn" style="flex:1">Add to Cart</button>
                <button class="qv-wish-btn ${wished ? 'active' : ''}" id="qv-wish-btn">${wished ? '&#10084;' : '&#9825;'}</button>
              </div>
              <button class="btn btn-outline" id="qv-buy-btn" style="margin-top:10px">Buy Now</button>
              <div class="qv-pay-row">
                <span class="pay-chip">UPI</span>
                <span class="pay-chip">VISA</span>
                <span class="pay-chip">Mastercard</span>
                <span class="pay-chip">RuPay</span>
                <span class="pay-chip">Net Banking</span>
              </div>
              <a href="/product.html?id=${encodeURIComponent(product.id)}" class="muted" style="margin-top:14px;font-size:13px;text-align:center;text-decoration:none">View full details &rarr;</a>
            </div>
          </div>
        </div>
      `;

      if (images.length > 1) {
        const dotsEl = backdrop.querySelector('#qv-dots');
        images.forEach((_, i) => {
          const dot = document.createElement('span');
          dot.className = 'dot' + (i === index ? ' active' : '');
          dot.addEventListener('click', () => { index = i; render(); });
          dotsEl.appendChild(dot);
        });
      }

      backdrop.querySelector('#qv-close').addEventListener('click', close);
      backdrop.querySelector('#qv-qty-minus').addEventListener('click', () => {
        quantity = Math.max(1, quantity - 1);
        backdrop.querySelector('#qv-qty-value').textContent = quantity;
      });
      backdrop.querySelector('#qv-qty-plus').addEventListener('click', () => {
        quantity = Math.min(10, quantity + 1);
        backdrop.querySelector('#qv-qty-value').textContent = quantity;
      });
      backdrop.querySelector('#qv-add-btn').addEventListener('click', async () => {
        if (!requireLogin()) return;
        try {
          await apiFetch('/cart', { method: 'POST', body: JSON.stringify({ productId: product.id, quantity }) });
          toast(`${product.name} added to cart`);
          refreshCartCount();
          close();
        } catch (e) { toast(e.message); }
      });
      backdrop.querySelector('#qv-buy-btn').addEventListener('click', async () => {
        if (!requireLogin()) return;
        try {
          await apiFetch('/cart', { method: 'POST', body: JSON.stringify({ productId: product.id, quantity }) });
          const cart = await apiFetch('/cart');
          const amount = cart.reduce((sum, i) => sum + i.price * i.quantity, 0);
          const paid = await showPaymentSheet(amount);
          if (!paid) return;
          await apiFetch('/orders/checkout', { method: 'POST' });
          refreshCartCount();
          toast('Order placed successfully!');
          close();
          window.location.href = '/orders.html';
        } catch (e) { toast(e.message); }
      });
      backdrop.querySelector('#qv-wish-btn').addEventListener('click', async () => {
        if (!requireLogin()) return;
        const btn = backdrop.querySelector('#qv-wish-btn');
        try {
          if (wished) {
            await apiFetch(`/wishlist/${product.id}`, { method: 'DELETE' });
          } else {
            await apiFetch('/wishlist', { method: 'POST', body: JSON.stringify({ productId: product.id }) });
          }
          wished = !wished;
          btn.classList.toggle('active', wished);
          btn.innerHTML = wished ? '&#10084;' : '&#9825;';
        } catch (e) { toast(e.message); }
      });
    }

    render();
    document.body.appendChild(backdrop);
  }

  return {
    getToken, getUser, setSession, clearSession, isLoggedIn,
    apiFetch, formatInr, imageSrc, productImages, attachHoverScrub, toast,
    renderNav, updateNavAuthState, refreshCartCount, requireLogin, showPaymentSheet,
    showQuickView,
  };
})();
