const express = require("express");
const prisma = require("../lib/prisma");
const HttpError = require("../lib/httpError");
const requireAuth = require("../middleware/auth");

const router = express.Router();
router.use(requireAuth);

router.get("/", async (req, res, next) => {
  try {
    const messages = await prisma.chatMessage.findMany({
      where: { userId: req.userId },
      orderBy: { createdAt: "asc" },
    });
    await prisma.chatMessage.updateMany({
      where: { userId: req.userId, sender: "admin", read: false },
      data: { read: true },
    });
    res.status(200).json(messages);
  } catch (error) {
    next(error);
  }
});

router.post("/", async (req, res, next) => {
  try {
    const { message } = req.body || {};
    if (!message || !message.trim()) {
      throw new HttpError(400, "message is required");
    }
    const chatMessage = await prisma.chatMessage.create({
      data: { userId: req.userId, sender: "customer", message: message.trim() },
    });
    res.status(201).json(chatMessage);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
