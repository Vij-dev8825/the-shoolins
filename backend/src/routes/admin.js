const express = require("express");
const jwt = require("jsonwebtoken");
const prisma = require("../lib/prisma");
const HttpError = require("../lib/httpError");
const requireAdmin = require("../middleware/adminAuth");

const router = express.Router();

const TOKEN_EXPIRY = "12h";
const CATEGORIES = ["men", "women"];

function toAdminProduct(product) {
  return {
    id: product.id,
    name: product.name,
    price: Number(product.price),
    image: product.image,
    imageBase64: product.imageBase64,
    imagesBase64: product.imagesBase64,
    category: product.category,
  };
}

function validateImagesBase64(imagesBase64) {
  if (imagesBase64 === undefined) return true;
  return Array.isArray(imagesBase64) && imagesBase64.every((img) => typeof img === "string");
}

router.post("/login", (req, res, next) => {
  try {
    const { password } = req.body || {};
    if (!password || password !== process.env.ADMIN_PASSWORD) {
      throw new HttpError(401, "Incorrect password");
    }
    const token = jwt.sign({ role: "admin" }, process.env.JWT_SECRET, { expiresIn: TOKEN_EXPIRY });
    res.status(200).json({ token });
  } catch (error) {
    next(error);
  }
});

router.use(requireAdmin);

router.get("/products", async (req, res, next) => {
  try {
    const products = await prisma.product.findMany({ orderBy: { name: "asc" } });
    res.status(200).json(products.map(toAdminProduct));
  } catch (error) {
    next(error);
  }
});

router.post("/products", async (req, res, next) => {
  try {
    const { name, price, category, imageBase64, imagesBase64 } = req.body || {};

    if (!name || !price || !category) {
      throw new HttpError(400, "name, price, and category are required");
    }
    if (!CATEGORIES.includes(category)) {
      throw new HttpError(400, `category must be one of: ${CATEGORIES.join(", ")}`);
    }
    if (!validateImagesBase64(imagesBase64)) {
      throw new HttpError(400, "imagesBase64 must be an array of strings");
    }

    const product = await prisma.product.create({
      data: {
        name,
        price,
        category,
        image: "",
        imageBase64: imageBase64 || null,
        imagesBase64: imagesBase64 || [],
      },
    });
    res.status(201).json(toAdminProduct(product));
  } catch (error) {
    next(error);
  }
});

router.patch("/products/:id", async (req, res, next) => {
  try {
    const { name, price, category, imageBase64, imagesBase64 } = req.body || {};

    if (category && !CATEGORIES.includes(category)) {
      throw new HttpError(400, `category must be one of: ${CATEGORIES.join(", ")}`);
    }
    if (!validateImagesBase64(imagesBase64)) {
      throw new HttpError(400, "imagesBase64 must be an array of strings");
    }

    const data = {};
    if (name !== undefined) data.name = name;
    if (price !== undefined) data.price = price;
    if (category !== undefined) data.category = category;
    if (imageBase64 !== undefined) data.imageBase64 = imageBase64;
    if (imagesBase64 !== undefined) data.imagesBase64 = imagesBase64;

    const product = await prisma.product.update({
      where: { id: req.params.id },
      data,
    });
    res.status(200).json(toAdminProduct(product));
  } catch (error) {
    if (error.code === "P2025") {
      return next(new HttpError(404, "Product not found"));
    }
    next(error);
  }
});

router.delete("/products/:id", async (req, res, next) => {
  try {
    await prisma.product.delete({ where: { id: req.params.id } });
    res.status(204).send();
  } catch (error) {
    if (error.code === "P2025") {
      return next(new HttpError(404, "Product not found"));
    }
    next(error);
  }
});

router.get("/enquiries", async (req, res, next) => {
  try {
    const enquiries = await prisma.enquiry.findMany({ orderBy: { createdAt: "desc" } });
    res.status(200).json(enquiries);
  } catch (error) {
    next(error);
  }
});

router.get("/contact-messages", async (req, res, next) => {
  try {
    const messages = await prisma.contactMessage.findMany({ orderBy: { createdAt: "desc" } });
    res.status(200).json(messages);
  } catch (error) {
    next(error);
  }
});

// One row per customer who has ever messaged, newest conversation first,
// with an unread count driven by unseen customer messages.
router.get("/chat/conversations", async (req, res, next) => {
  try {
    const messages = await prisma.chatMessage.findMany({
      orderBy: { createdAt: "desc" },
      include: { user: { select: { id: true, name: true, mobile: true } } },
    });
    const conversations = new Map();
    for (const m of messages) {
      if (!conversations.has(m.userId)) {
        conversations.set(m.userId, {
          userId: m.userId,
          name: m.user.name || m.user.mobile,
          mobile: m.user.mobile,
          lastMessage: m.message,
          lastMessageAt: m.createdAt,
          unreadCount: 0,
        });
      }
    }
    const unread = await prisma.chatMessage.groupBy({
      by: ["userId"],
      where: { sender: "customer", read: false },
      _count: { _all: true },
    });
    for (const u of unread) {
      if (conversations.has(u.userId)) {
        conversations.get(u.userId).unreadCount = u._count._all;
      }
    }
    res.status(200).json([...conversations.values()]);
  } catch (error) {
    next(error);
  }
});

router.get("/chat/conversations/:userId", async (req, res, next) => {
  try {
    const messages = await prisma.chatMessage.findMany({
      where: { userId: req.params.userId },
      orderBy: { createdAt: "asc" },
    });
    await prisma.chatMessage.updateMany({
      where: { userId: req.params.userId, sender: "customer", read: false },
      data: { read: true },
    });
    res.status(200).json(messages);
  } catch (error) {
    next(error);
  }
});

router.post("/chat/conversations/:userId/reply", async (req, res, next) => {
  try {
    const { message } = req.body || {};
    if (!message || !message.trim()) {
      throw new HttpError(400, "message is required");
    }
    const user = await prisma.user.findUnique({ where: { id: req.params.userId } });
    if (!user) {
      throw new HttpError(404, "Customer not found");
    }
    const chatMessage = await prisma.chatMessage.create({
      data: { userId: req.params.userId, sender: "admin", message: message.trim() },
    });
    res.status(201).json(chatMessage);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
