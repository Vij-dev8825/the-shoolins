const express = require("express");
const path = require("path");
const cors = require("cors");
const authRoutes = require("./routes/auth");
const productRoutes = require("./routes/products");
const cartRoutes = require("./routes/cart");
const orderRoutes = require("./routes/orders");
const wishlistRoutes = require("./routes/wishlist");
const reviewRoutes = require("./routes/reviews");
const enquiryRoutes = require("./routes/enquiries");
const newsletterRoutes = require("./routes/newsletter");
const contactRoutes = require("./routes/contact");
const adminRoutes = require("./routes/admin");
const { notFoundHandler, errorHandler } = require("./middleware/errorHandler");

const app = express();

app.use(cors());
// Product images go through here as base64, so the default 100kb JSON body
// limit needs raising — the admin page also downsizes images client-side
// before upload, but this leaves headroom.
app.use(express.json({ limit: "8mb" }));

// Serves the public marketing pages (/, /about.html, /contact.html) as well
// as the admin panel (public/admin/index.html, reachable at /admin/).
// HTML/JS/CSS get no-cache so a deployed fix always takes effect on next
// load — several pages (e.g. product.html) carry their own inline <style>
// block, so the HTML document itself needs this too, not just shop.css/
// shop.js. Mobile browsers and carrier data-compression proxies otherwise
// keep serving a stale cached copy indefinitely after every fix.
app.use(express.static(path.join(__dirname, "../public"), {
  setHeaders: (res, filePath) => {
    if (filePath.endsWith(".js") || filePath.endsWith(".css") || filePath.endsWith(".html")) {
      res.setHeader("Cache-Control", "no-cache");
    }
  },
}));

app.use("/api/auth", authRoutes);
app.use("/api/products", productRoutes);
app.use("/api/cart", cartRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/wishlist", wishlistRoutes);
app.use("/api/reviews", reviewRoutes);
app.use("/api/enquiries", enquiryRoutes);
app.use("/api/newsletter", newsletterRoutes);
app.use("/api/contact", contactRoutes);
app.use("/api/admin", adminRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
