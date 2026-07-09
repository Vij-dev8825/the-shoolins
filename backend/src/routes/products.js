const express = require("express");
const prisma = require("../lib/prisma");
const HttpError = require("../lib/httpError");

const router = express.Router();

function toPublicProduct(product) {
  return {
    id: product.id,
    name: product.name,
    price: Number(product.price),
    image: product.image,
    imageBase64: product.imageBase64,
    category: product.category,
  };
}

const SORTS = {
  price_asc: { price: "asc" },
  price_desc: { price: "desc" },
  name_asc: { name: "asc" },
};

router.get("/", async (req, res, next) => {
  try {
    const { category, q, sort } = req.query;
    const products = await prisma.product.findMany({
      where: {
        category: category || undefined,
        name: q ? { contains: q } : undefined,
      },
      orderBy: SORTS[sort] || undefined,
    });
    res.status(200).json(products.map(toPublicProduct));
  } catch (error) {
    next(error);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    const product = await prisma.product.findUnique({ where: { id: req.params.id } });
    if (!product) {
      throw new HttpError(404, "Product not found");
    }
    res.status(200).json(toPublicProduct(product));
  } catch (error) {
    next(error);
  }
});

module.exports = router;
