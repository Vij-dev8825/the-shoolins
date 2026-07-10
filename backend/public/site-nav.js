(function () {
  const token = localStorage.getItem('admin_token');
  const adminLink = document.getElementById('nav-admin');
  const productsLink = document.getElementById('nav-products');
  const logoutBtn = document.getElementById('nav-logout');

  if (token) {
    if (adminLink) adminLink.style.display = 'none';
    if (productsLink) productsLink.style.display = '';
    if (logoutBtn) logoutBtn.style.display = '';
  }

  if (logoutBtn) {
    logoutBtn.addEventListener('click', () => {
      localStorage.removeItem('admin_token');
      window.location.href = '/';
    });
  }
})();
