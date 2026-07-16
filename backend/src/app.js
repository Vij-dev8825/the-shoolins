const express = require("express");
const path = require("path");
const fs = require("fs");
const cors = require("cors");
const prisma = require("./lib/prisma");
const authRoutes = require("./routes/auth");
const productRoutes = require("./routes/products");
const cartRoutes = require("./routes/cart");
const orderRoutes = require("./routes/orders");
const wishlistRoutes = require("./routes/wishlist");
const reviewRoutes = require("./routes/reviews");
const enquiryRoutes = require("./routes/enquiries");
const newsletterRoutes = require("./routes/newsletter");
const contactRoutes = require("./routes/contact");
const chatRoutes = require("./routes/chat");
const adminRoutes = require("./routes/admin");
const { notFoundHandler, errorHandler } = require("./middleware/errorHandler");

const app = express();

// Render terminates SSL upstream and proxies to this app over plain HTTP,
// so req.protocol reports "http" unless Express is told to trust the
// X-Forwarded-Proto header — needed for the OG tag URLs below to read
// https, not http.
app.set("trust proxy", 1);

app.use(cors());
// Product images go through here as base64, so the default 100kb JSON body
// limit needs raising — the admin page also downsizes images client-side
// before upload, but this leaves headroom.
app.use(express.json({ limit: "8mb" }));

// product.html carries {{OG_...}} placeholders instead of static Open
// Graph tags — fill them in with the actual product's name/price/photo
// before express.static below would otherwise serve the raw file, so a
// link shared on WhatsApp/Instagram previews the real product instead of
// a generic site card.
const PRODUCT_HTML_PATH = path.join(__dirname, "../public/product.html");
app.get("/product.html", async (req, res, next) => {
  try {
    const baseUrl = `${req.protocol}://${req.get("host")}`;
    let ogTitle = "The Shoolins";
    let ogDescription = "Considered fashion essentials, crafted for everyday elegance.";
    let ogImage = `${baseUrl}/media/logo.png`;

    const id = req.query.id;
    if (id) {
      const product = await prisma.product.findUnique({ where: { id } });
      if (product) {
        ogTitle = `${product.name} — The Shoolins`;
        ogDescription = `${product.name} — ₹${Number(product.price).toLocaleString("en-IN")} at The Shoolins.`;
        ogImage = `${baseUrl}/api/products/${product.id}/image`;
      }
    }

    const template = fs.readFileSync(PRODUCT_HTML_PATH, "utf8");
    const html = template
      .replaceAll("{{OG_TITLE}}", ogTitle)
      .replaceAll("{{OG_DESCRIPTION}}", ogDescription)
      .replaceAll("{{OG_IMAGE}}", ogImage)
      .replaceAll("{{OG_URL}}", `${baseUrl}${req.originalUrl}`);

    res.set("Content-Type", "text/html").set("Cache-Control", "no-cache").send(html);
  } catch (error) {
    next(error);
  }
});

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
app.use("/api/chat", chatRoutes);
app.use("/api/admin", adminRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
