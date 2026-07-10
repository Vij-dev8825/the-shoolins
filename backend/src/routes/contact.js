const express = require("express");
const prisma = require("../lib/prisma");
const HttpError = require("../lib/httpError");

const router = express.Router();

router.post("/", async (req, res, next) => {
  try {
    const { name, email, phone, message } = req.body || {};

    if (!name || !email || !message) {
      throw new HttpError(400, "name, email, and message are required");
    }

    const contactMessage = await prisma.contactMessage.create({
      data: { name, email, phone: phone || null, message },
    });
    res.status(201).json({ id: contactMessage.id, received: true });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
