const express = require("express");
const prisma = require("../lib/prisma");
const HttpError = require("../lib/httpError");

const router = express.Router();

router.post("/", async (req, res, next) => {
  try {
    const { email } = req.body || {};

    if (!email || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      throw new HttpError(400, "a valid email is required");
    }

    await prisma.newsletterSubscriber.upsert({
      where: { email },
      update: {},
      create: { email },
    });
    res.status(201).json({ subscribed: true });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
