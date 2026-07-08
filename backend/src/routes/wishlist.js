const express = require("express");
const prisma = require("../lib/prisma");
const HttpError = require("../lib/httpError");
const requireAuth = require("../middleware/auth");

const router = express.Router();

router.use(requireAuth);

function toWishlistResponse(wishlistItem) {
  return {
    productId: wishlistItem.product.id,
    name: wishlistItem.product.name,
    price: Number(wishlistItem.product.price),
    image: wishlistItem.product.image,
    category: wishlistItem.product.category,
  };
}

async function getWishlistForUser(userId) {
  const items = await prisma.wishlistItem.findMany({
    where: { userId },
    include: { product: true },
    orderBy: { createdAt: "desc" },
  });
  return items.map(toWishlistResponse);
}

router.get("/", async (req, res, next) => {
  try {
    res.status(200).json(await getWishlistForUser(req.userId));
  } catch (error) {
    next(error);
  }
});

router.post("/", async (req, res, next) => {
  try {
    const { productId } = req.body || {};

    if (!productId) {
      throw new HttpError(400, "productId is required");
    }

    const product = await prisma.product.findUnique({ where: { id: productId } });
    if (!product) {
      throw new HttpError(404, "Product not found");
    }

    await prisma.wishlistItem.upsert({
      where: { userId_productId: { userId: req.userId, productId } },
      update: {},
      create: { userId: req.userId, productId },
    });

    res.status(200).json(await getWishlistForUser(req.userId));
  } catch (error) {
    next(error);
  }
});

router.delete("/:productId", async (req, res, next) => {
  try {
    await prisma.wishlistItem.deleteMany({
      where: { userId: req.userId, productId: req.params.productId },
    });
    res.status(200).json(await getWishlistForUser(req.userId));
  } catch (error) {
    next(error);
  }
});

module.exports = router;
