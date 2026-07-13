const API = '/api';
const WHATSAPP_BUSINESS_NUMBER = '919487682924';

const BROKEN_IMAGE = 'data:image/svg+xml,' + encodeURIComponent(
  '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200">'
  + '<rect width="200" height="200" fill="#e6ddc8"/>'
  + '<g stroke="#766f5d" stroke-width="6" fill="none" stroke-linecap="round" stroke-linejoin="round">'
  + '<rect x="40" y="55" width="120" height="90" rx="8"/>'
  + '<circle cx="75" cy="85" r="12"/>'
  + '<path d="M40 130l35-30 25 20 30-35 30 35"/>'
  + '</g></svg>'
);

function markBrokenImagesWithFallback(root) {
  root.querySelectorAll('img').forEach((img) => {
    img.addEventListener('error', () => {
      img.onerror = null;
      img.src = BROKEN_IMAGE;
    }, { once: true });
  });
}

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

  // Real image URLs (served by the backend, not embedded as data: URIs) for
  // a current product's cover + gallery photos. Used by the quick-view
  // modal and the product detail page, where several large inline
  // base64-encoded images on one page have proven unreliable on some
  // mobile browsers. Only usable for a live product with a real id — cart/
  // order/wishlist snapshots keep using the embedded data: URI (imageSrc/
  // productImages above) since that data must survive the product being
  // deleted later.
  function productGalleryUrls(product) {
    const count = (product.imagesBase64 || []).length;
    const urls = [`${API}/products/${product.id}/image`];
    for (let i = 0; i < count; i++) urls.push(`${API}/products/${product.id}/image/${i}`);
    return urls;
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
            <button class="nav-burger" id="nav-burger" aria-label="Menu"><span></span><span></span><span></span></button>
            <nav id="nav-links">
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
    document.getElementById('nav-burger').addEventListener('click', () => {
      document.getElementById('nav-links').classList.toggle('open');
    });
    if (hasI18n) {
      I18N.apply(mount);
      document.getElementById('lang-select').addEventListener('change', (e) => {
        I18N.setLang(e.target.value);
        window.location.reload();
      });
    }
  }

  function updateNavAuthState() { renderNav(); }

  // ---------- Footer (rich multi-column footer + scroll-to-top, shared across all pages) ----------
  function renderFooter() {
    const mount = document.getElementById('shop-footer-mount');
    if (!mount) return;
    const year = new Date().getFullYear();

    mount.innerHTML = `
      <footer class="site-footer-premium">
        <div class="footer-main">
          <div class="footer-col">
            <p class="footer-brand-name">THE SHOOLINS</p>
            <div class="footer-contact-item">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 21s-7-6.5-7-11a7 7 0 1 1 14 0c0 4.5-7 11-7 11z"/><circle cx="12" cy="10" r="2.5"/></svg>
              <span>Coimbatore, Tamil Nadu, India</span>
            </div>
            <div class="footer-contact-item">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="5" width="18" height="14" rx="2"/><path d="M3 7l9 6 9-6"/></svg>
              <span>hello@theshoolins.example</span>
            </div>
            <div class="footer-contact-item">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z"/></svg>
              <span>+91 94876 82924</span>
            </div>
            <div class="footer-social">
              <a href="https://www.instagram.com/the_shoolins" target="_blank" rel="noopener" title="Instagram" class="footer-social-icon">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="2" width="20" height="20" rx="5"/><circle cx="12" cy="12" r="4"/><circle cx="17.5" cy="6.5" r="1" fill="currentColor" stroke="none"/></svg>
              </a>
              <a href="https://wa.me/${WHATSAPP_BUSINESS_NUMBER}" target="_blank" rel="noopener" title="WhatsApp" class="footer-social-icon">
                <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12.04 2c-5.46 0-9.91 4.45-9.91 9.91 0 1.75.46 3.45 1.32 4.95L2 22l5.25-1.38c1.45.79 3.08 1.21 4.79 1.21 5.46 0 9.91-4.45 9.91-9.91S17.5 2 12.04 2zm0 1.67c4.55 0 8.25 3.7 8.25 8.24 0 4.55-3.7 8.25-8.25 8.25-1.6 0-3.15-.46-4.5-1.32l-.32-.2-3.12.82.83-3.04-.21-.32a8.18 8.18 0 0 1-1.26-4.19c0-4.54 3.7-8.24 8.25-8.24h.33zm-4.6 4.62c-.15 0-.4.06-.58.27-.19.21-.72.71-.72 1.73 0 1.02.74 2 .84 2.15.1.14 1.4 2.24 3.45 3.05 1.7.68 2.05.55 2.42.51.37-.04 1.2-.49 1.37-.96.17-.47.17-.87.12-.96-.05-.1-.19-.16-.4-.27-.21-.11-1.25-.62-1.44-.69-.19-.07-.34-.11-.48.11-.14.21-.55.69-.68.83-.12.14-.25.15-.46.05-.21-.1-.9-.33-1.72-1.06-.63-.56-1.05-1.25-1.18-1.46-.12-.21-.01-.32.1-.43.11-.11.25-.28.37-.42.12-.14.16-.24.24-.4.08-.16.04-.31-.02-.42-.06-.11-.5-1.2-.68-1.65-.16-.4-.34-.35-.48-.36h-.42z"/></svg>
              </a>
            </div>
          </div>
          <div class="footer-col">
            <h4>Categories</h4>
            <a href="/shop.html">Shop All</a>
            <a href="/shop.html?category=women">Women</a>
            <a href="/shop.html?category=men">Men</a>
            <a href="/combos.html">Combos</a>
          </div>
          <div class="footer-col">
            <h4>Information</h4>
            <a href="/about.html">About Us</a>
            <a href="/privacy-policy.html">Privacy Policy</a>
            <a href="/refund-policy.html">Refund Policy</a>
            <a href="/shipping-policy.html">Shipping Policy</a>
            <a href="/terms-of-service.html">Terms of Service</a>
          </div>
          <div class="footer-col">
            <h4>Useful Links</h4>
            <a href="/">Home</a>
            <a href="/reviews.html">Reviews</a>
            <a href="/bulk-enquiry.html">Bulk Enquiry</a>
            <a href="/contact.html">Contact Us</a>
          </div>
          <div class="footer-col footer-newsletter">
            <h4>Newsletter Signup</h4>
            <p>Subscribe for updates on new arrivals and offers.</p>
            <div class="footer-newsletter-row">
              <input type="email" id="footer-newsletter-email" placeholder="Your email address" />
              <button class="btn btn-gold shine" id="footer-newsletter-btn">Subscribe</button>
            </div>
          </div>
        </div>
        <div class="footer-bottom">
          <p style="margin:0">&copy; ${year} The Shoolins. <span data-i18n="footerRights">All rights reserved.</span></p>
          <div class="footer-bottom-links">
            <a href="/privacy-policy.html">Privacy Policy</a>
            <a href="/refund-policy.html">Refund Policy</a>
            <a href="/shipping-policy.html">Shipping Policy</a>
            <a href="/terms-of-service.html">Terms of Service</a>
            <a href="/contact.html">Contact Us</a>
          </div>
        </div>
      </footer>
      <button class="scroll-top-btn" id="scroll-top-btn" title="Back to top">&uarr;</button>
      <a class="whatsapp-chat-btn" id="whatsapp-chat-btn" title="Chat with us on WhatsApp" target="_blank" rel="noopener">
        <svg viewBox="0 0 24 24" fill="currentColor"><path d="M12.04 2c-5.46 0-9.91 4.45-9.91 9.91 0 1.75.46 3.45 1.32 4.95L2 22l5.25-1.38c1.45.79 3.08 1.21 4.79 1.21 5.46 0 9.91-4.45 9.91-9.91S17.5 2 12.04 2zm0 1.67c4.55 0 8.25 3.7 8.25 8.24 0 4.55-3.7 8.25-8.25 8.25-1.6 0-3.15-.46-4.5-1.32l-.32-.2-3.12.82.83-3.04-.21-.32a8.18 8.18 0 0 1-1.26-4.19c0-4.54 3.7-8.24 8.25-8.24h.33zm-4.6 4.62c-.15 0-.4.06-.58.27-.19.21-.72.71-.72 1.73 0 1.02.74 2 .84 2.15.1.14 1.4 2.24 3.45 3.05 1.7.68 2.05.55 2.42.51.37-.04 1.2-.49 1.37-.96.17-.47.17-.87.12-.96-.05-.1-.19-.16-.4-.27-.21-.11-1.25-.62-1.44-.69-.19-.07-.34-.11-.48.11-.14.21-.55.69-.68.83-.12.14-.25.15-.46.05-.21-.1-.9-.33-1.72-1.06-.63-.56-1.05-1.25-1.18-1.46-.12-.21-.01-.32.1-.43.11-.11.25-.28.37-.42.12-.14.16-.24.24-.4.08-.16.04-.31-.02-.42-.06-.11-.5-1.2-.68-1.65-.16-.4-.34-.35-.48-.36h-.42z"/></svg>
      </a>
    `;

    if (typeof I18N !== 'undefined') I18N.apply(mount);

    const emailInput = mount.querySelector('#footer-newsletter-email');
    mount.querySelector('#footer-newsletter-btn').addEventListener('click', async () => {
      const email = emailInput.value.trim();
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        toast('Enter a valid email address.');
        return;
      }
      try {
        await apiFetch('/newsletter', { method: 'POST', body: JSON.stringify({ email }) });
        toast('Thanks for subscribing!');
        emailInput.value = '';
      } catch (e) {
        toast(e.message);
      }
    });

    const scrollBtn = mount.querySelector('#scroll-top-btn');
    window.addEventListener('scroll', () => {
      scrollBtn.classList.toggle('visible', window.scrollY > 400);
    });
    scrollBtn.addEventListener('click', () => {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });

    const whatsappBtn = mount.querySelector('#whatsapp-chat-btn');
    whatsappBtn.href = `https://wa.me/${WHATSAPP_BUSINESS_NUMBER}?text=${encodeURIComponent('Hi! I have a question about The Shoolins.')}`;
  }

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
    const images = productGalleryUrls(product);
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

    backdrop.innerHTML = `
      <div class="modal-sheet quickview">
        <button class="modal-close-btn" id="qv-close">&times;</button>
        <div class="qv-body">
          <div class="qv-image">
            <div class="qv-slides-track" id="qv-slides-track"></div>
            ${images.length > 1 ? `
              <button class="qv-arrow-btn prev" id="qv-prev" title="Previous"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M15 18l-6-6 6-6"/></svg></button>
              <button class="qv-arrow-btn next" id="qv-next" title="Next"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><path d="M9 18l6-6-6-6"/></svg></button>
              <div class="gallery-dots" id="qv-dots"></div>
            ` : ''}
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
            <div style="display:flex;gap:10px;margin-top:4px">
              <button class="btn btn-gold shine" id="qv-add-btn" style="flex:1">Add to Cart</button>
              <button class="qv-wish-btn ${wished ? 'active' : ''}" id="qv-wish-btn">${wished ? '&#10084;' : '&#9825;'}</button>
              <button class="qv-wish-btn" id="qv-share-btn" title="Share on WhatsApp" style="color:#25d366;border-color:#25d366"><svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor"><path d="M12.04 2c-5.46 0-9.91 4.45-9.91 9.91 0 1.75.46 3.45 1.32 4.95L2 22l5.25-1.38c1.45.79 3.08 1.21 4.79 1.21 5.46 0 9.91-4.45 9.91-9.91S17.5 2 12.04 2zm0 1.67c4.55 0 8.25 3.7 8.25 8.24 0 4.55-3.7 8.25-8.25 8.25-1.6 0-3.15-.46-4.5-1.32l-.32-.2-3.12.82.83-3.04-.21-.32a8.18 8.18 0 0 1-1.26-4.19c0-4.54 3.7-8.24 8.25-8.24h.33zm-4.6 4.62c-.15 0-.4.06-.58.27-.19.21-.72.71-.72 1.73 0 1.02.74 2 .84 2.15.1.14 1.4 2.24 3.45 3.05 1.7.68 2.05.55 2.42.51.37-.04 1.2-.49 1.37-.96.17-.47.17-.87.12-.96-.05-.1-.19-.16-.4-.27-.21-.11-1.25-.62-1.44-.69-.19-.07-.34-.11-.48.11-.14.21-.55.69-.68.83-.12.14-.25.15-.46.05-.21-.1-.9-.33-1.72-1.06-.63-.56-1.05-1.25-1.18-1.46-.12-.21-.01-.32.1-.43.11-.11.25-.28.37-.42.12-.14.16-.24.24-.4.08-.16.04-.31-.02-.42-.06-.11-.5-1.2-.68-1.65-.16-.4-.34-.35-.48-.36h-.42z"/></svg></button>
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

    document.body.appendChild(backdrop);

    // Images are fetched from real backend URLs (productGalleryUrls) rather
    // than embedded as data: URIs — several large base64-encoded images
    // inline on one page proved unreliable on some mobile browsers; a
    // normal <img src="url"> goes through the standard network image
    // pipeline instead.
    const qvTrack = backdrop.querySelector('#qv-slides-track');
    images.forEach((src) => {
      const imgEl = document.createElement('img');
      imgEl.alt = product.name;
      imgEl.draggable = false;
      imgEl.src = src;
      qvTrack.appendChild(imgEl);
    });
    markBrokenImagesWithFallback(backdrop);

    // Pointer-driven carousel (matches the product detail page's gallery) so
    // dragging the image cycles through photos instead of leaving the only
    // interaction as small dot clicks.
    if (images.length > 1) {
      const track = backdrop.querySelector('#qv-slides-track');
      const dotsEl = backdrop.querySelector('#qv-dots');
      let index = 0;
      let pointerActive = false;
      let dragging = false;
      let directionDecided = false;
      let dragStartX = 0;
      let dragStartY = 0;
      let dragDeltaX = 0;

      images.forEach((_, i) => {
        const dot = document.createElement('span');
        dot.className = 'dot' + (i === 0 ? ' active' : '');
        dot.addEventListener('click', () => goTo(i));
        dotsEl.appendChild(dot);
      });

      function goTo(i) {
        index = Math.max(0, Math.min(images.length - 1, i));
        track.style.transition = 'transform 0.3s ease';
        track.style.transform = `translateX(-${index * 100}%)`;
        dotsEl.querySelectorAll('.dot').forEach((d, i2) => d.classList.toggle('active', i2 === index));
      }

      backdrop.querySelector('#qv-prev').addEventListener('click', () => goTo(index - 1 < 0 ? images.length - 1 : index - 1));
      backdrop.querySelector('#qv-next').addEventListener('click', () => goTo(index + 1 >= images.length ? 0 : index + 1));

      track.addEventListener('pointerdown', (e) => {
        pointerActive = true;
        dragStartX = e.clientX;
        dragStartY = e.clientY;
        dragDeltaX = 0;
        dragging = false;
        directionDecided = false;
      });
      // Direction is decided only once the gesture has moved a few pixels —
      // capturing the pointer immediately on pointerdown hijacked every
      // touch, including a plain vertical scroll inside the modal. Bailing
      // out when the pointer was never actually pressed also matters: a
      // plain hover fires pointermove too, and without this check the
      // stale dragStartX/dragStartY (from before any press) would be
      // diffed against the live cursor position, producing a huge fake
      // "drag" delta that shoved the whole track off-screen.
      track.addEventListener('pointermove', (e) => {
        if (!pointerActive) return;
        if (directionDecided && !dragging) return;
        const deltaX = e.clientX - dragStartX;
        const deltaY = e.clientY - dragStartY;
        if (!directionDecided) {
          if (Math.abs(deltaX) < 8 && Math.abs(deltaY) < 8) return;
          directionDecided = true;
          if (Math.abs(deltaX) <= Math.abs(deltaY)) return;
          dragging = true;
          track.style.transition = 'none';
          track.style.cursor = 'grabbing';
          try { track.setPointerCapture(e.pointerId); } catch (err) { /* pointer already released — ignore */ }
        }
        if (!dragging) return;
        dragDeltaX = deltaX;
        track.style.transform = `translateX(calc(-${index * 100}% + ${dragDeltaX}px))`;
      });
      function endDrag() {
        if (dragging) {
          dragging = false;
          track.style.cursor = 'grab';
          if (dragDeltaX < -50 && index < images.length - 1) goTo(index + 1);
          else if (dragDeltaX > 50 && index > 0) goTo(index - 1);
          else goTo(index);
        }
        pointerActive = false;
        directionDecided = false;
      }
      track.addEventListener('pointerup', endDrag);
      track.addEventListener('pointercancel', endDrag);
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
    backdrop.querySelector('#qv-share-btn').addEventListener('click', () => {
      const url = `${window.location.origin}/product.html?id=${encodeURIComponent(product.id)}&utm_source=whatsapp&utm_medium=share`;
      const text = `${product.name} — ${formatInr(product.price)} at The Shoolins\n${url}`;
      window.open(`https://wa.me/?text=${encodeURIComponent(text)}`, '_blank');
    });
  }

  return {
    getToken, getUser, setSession, clearSession, isLoggedIn,
    apiFetch, formatInr, imageSrc, productImages, productGalleryUrls, attachHoverScrub, toast,
    renderNav, updateNavAuthState, renderFooter, refreshCartCount, requireLogin, showPaymentSheet,
    showQuickView, markBrokenImagesWithFallback,
  };
})();
