const express = require("express");
const prisma = require("../lib/prisma");
const HttpError = require("../lib/httpError");
const requireAuth = require("../middleware/auth");

const router = express.Router();

function toReviewResponse(review) {
  return {
    id: review.id,
    name: review.user.name || "Anonymous",
    photoBase64: review.user.photoBase64,
    rating: review.rating,
    comment: review.comment,
    createdAt: review.createdAt,
  };
}

router.get("/", async (req, res, next) => {
  try {
    const reviews = await prisma.review.findMany({
      include: { user: true },
      orderBy: { createdAt: "desc" },
    });
    res.status(200).json(reviews.map(toReviewResponse));
  } catch (error) {
    next(error);
  }
});

router.post("/", requireAuth, async (req, res, next) => {
  try {
    const { rating, comment } = req.body || {};
    const ratingNum = Number(rating);

    if (!Number.isInteger(ratingNum) || ratingNum < 1 || ratingNum > 5) {
      throw new HttpError(400, "rating must be an integer from 1 to 5");
    }
    if (!comment || !comment.trim()) {
      throw new HttpError(400, "comment is required");
    }

    const review = await prisma.review.create({
      data: { userId: req.userId, rating: ratingNum, comment: comment.trim() },
      include: { user: true },
    });
    res.status(201).json(toReviewResponse(review));
  } catch (error) {
    next(error);
  }
});

module.exports = router;
