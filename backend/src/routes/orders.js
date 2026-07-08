const express = require("express");
const prisma = require("../lib/prisma");
const HttpError = require("../lib/httpError");
const requireAuth = require("../middleware/auth");

const router = express.Router();

router.use(requireAuth);

function toOrderResponse(order) {
  return {
    id: order.id,
    items: order.items.map((item) => ({
      productId: item.productId,
      name: item.name,
      price: Number(item.price),
      image: item.image,
      quantity: item.quantity,
    })),
    total: Number(order.total),
    createdAt: order.createdAt,
  };
}

router.post("/checkout", async (req, res, next) => {
  try {
    const cartItems = await prisma.cartItem.findMany({
      where: { userId: req.userId },
      include: { product: true },
    });

    if (cartItems.length === 0) {
      throw new HttpError(400, "Cart is empty");
    }

    const total = cartItems.reduce(
      (sum, item) => sum + Number(item.product.price) * item.quantity,
      0
    );

    const order = await prisma.$transaction(async (tx) => {
      const createdOrder = await tx.order.create({
        data: {
          userId: req.userId,
          total,
          items: {
            create: cartItems.map((item) => ({
              productId: item.product.id,
              name: item.product.name,
              price: item.product.price,
              image: item.product.image,
              quantity: item.quantity,
            })),
          },
        },
        include: { items: true },
      });

      await tx.cartItem.deleteMany({ where: { userId: req.userId } });

      return createdOrder;
    });

    res.status(201).json(toOrderResponse(order));
  } catch (error) {
    next(error);
  }
});

router.get("/", async (req, res, next) => {
  try {
    const orders = await prisma.order.findMany({
      where: { userId: req.userId },
      include: { items: true },
      orderBy: { createdAt: "desc" },
    });
    res.status(200).json(orders.map(toOrderResponse));
  } catch (error) {
    next(error);
  }
});

module.exports = router;
