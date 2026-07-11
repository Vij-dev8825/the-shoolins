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
    imagesBase64: product.imagesBase64,
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

// Serve the cover/gallery photos as real image responses instead of
// embedding them as data: URIs in the page — some mobile browsers are
// unreliable rendering several large base64-encoded images inline on the
// same page, but every browser's normal <img src="url"> network pipeline
// handles this fine.
router.get("/:id/image", async (req, res, next) => {
  try {
    const product = await prisma.product.findUnique({ where: { id: req.params.id } });
    if (!product) throw new HttpError(404, "Product not found");
    if (product.imageBase64) {
      res.set("Content-Type", "image/jpeg");
      res.set("Cache-Control", "public, max-age=3600");
      return res.send(Buffer.from(product.imageBase64, "base64"));
    }
    if (product.image) {
      return res.redirect(`/products-assets/${product.image}`);
    }
    throw new HttpError(404, "No image available");
  } catch (error) {
    next(error);
  }
});

router.get("/:id/image/:index", async (req, res, next) => {
  try {
    const product = await prisma.product.findUnique({ where: { id: req.params.id } });
    if (!product) throw new HttpError(404, "Product not found");
    const b64 = (product.imagesBase64 || [])[Number(req.params.index)];
    if (!b64) throw new HttpError(404, "Image not found");
    res.set("Content-Type", "image/jpeg");
    res.set("Cache-Control", "public, max-age=3600");
    res.send(Buffer.from(b64, "base64"));
  } catch (error) {
    next(error);
  }
});

module.exports = router;
