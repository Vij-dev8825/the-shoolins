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
app.use(express.static(path.join(__dirname, "../public")));

app.use("/api/auth", authRoutes);
app.use("/api/products", productRoutes);
app.use("/api/cart", cartRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/wishlist", wishlistRoutes);
app.use("/api/reviews", reviewRoutes);
app.use("/api/enquiries", enquiryRoutes);
app.use("/api/newsletter", newsletterRoutes);
app.use("/api/admin", adminRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
