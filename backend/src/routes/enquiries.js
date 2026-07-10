const express = require("express");
const prisma = require("../lib/prisma");
const HttpError = require("../lib/httpError");

const router = express.Router();

router.post("/", async (req, res, next) => {
  try {
    const { name, company, email, phone, productInterest, quantity, message } = req.body || {};

    if (!name || !email || !phone) {
      throw new HttpError(400, "name, email, and phone are required");
    }

    const enquiry = await prisma.enquiry.create({
      data: {
        name,
        company: company || null,
        email,
        phone,
        productInterest: productInterest || null,
        quantity: quantity || null,
        message: message || null,
      },
    });
    res.status(201).json({ id: enquiry.id, received: true });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
