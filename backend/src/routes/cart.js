const express = require("express");
const prisma = require("../lib/prisma");
const HttpError = require("../lib/httpError");
const requireAuth = require("../middleware/auth");

const router = express.Router();

router.use(requireAuth);

function toCartResponse(cartItem) {
  return {
    productId: cartItem.product.id,
    name: cartItem.product.name,
    price: Number(cartItem.product.price),
    image: cartItem.product.image,
    quantity: cartItem.quantity,
  };
}

async function getCartForUser(userId) {
  const cartItems = await prisma.cartItem.findMany({
    where: { userId },
    include: { product: true },
  });
  return cartItems.map(toCartResponse);
}

router.get("/", async (req, res, next) => {
  try {
    res.status(200).json(await getCartForUser(req.userId));
  } catch (error) {
    next(error);
  }
});

router.post("/", async (req, res, next) => {
  try {
    const { productId, quantity = 1 } = req.body || {};

    if (!productId) {
      throw new HttpError(400, "productId is required");
    }

    const product = await prisma.product.findUnique({ where: { id: productId } });
    if (!product) {
      throw new HttpError(404, "Product not found");
    }

    // upsert instead of find-then-create/update: two requests for the same
    // product landing close together (e.g. a rapid double-tap) could both
    // see "no existing row" and both try to create one, and the loser would
    // hit the userId_productId unique constraint as an unhandled 500.
    await prisma.cartItem.upsert({
      where: { userId_productId: { userId: req.userId, productId } },
      update: { quantity: { increment: quantity } },
      create: { userId: req.userId, productId, quantity },
    });

    res.status(200).json(await getCartForUser(req.userId));
  } catch (error) {
    next(error);
  }
});

router.patch("/:productId", async (req, res, next) => {
  try {
    const { quantity } = req.body || {};

    if (typeof quantity !== "number") {
      throw new HttpError(400, "quantity is required");
    }

    if (quantity <= 0) {
      await prisma.cartItem.deleteMany({
        where: { userId: req.userId, productId: req.params.productId },
      });
    } else {
      await prisma.cartItem.updateMany({
        where: { userId: req.userId, productId: req.params.productId },
        data: { quantity },
      });
    }

    res.status(200).json(await getCartForUser(req.userId));
  } catch (error) {
    next(error);
  }
});

router.delete("/:productId", async (req, res, next) => {
  try {
    await prisma.cartItem.deleteMany({
      where: { userId: req.userId, productId: req.params.productId },
    });
    res.status(200).json(await getCartForUser(req.userId));
  } catch (error) {
    next(error);
  }
});

router.delete("/", async (req, res, next) => {
  try {
    await prisma.cartItem.deleteMany({ where: { userId: req.userId } });
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

module.exports = router;
