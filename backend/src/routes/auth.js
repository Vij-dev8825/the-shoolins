const express = require("express");
const jwt = require("jsonwebtoken");
const prisma = require("../lib/prisma");
const HttpError = require("../lib/httpError");
const requireAuth = require("../middleware/auth");
const { sendOtp, verifyOtp } = require("../lib/msg91");

const router = express.Router();

const TOKEN_EXPIRY = "7d";

function signToken(userId) {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: TOKEN_EXPIRY });
}

const PROFILE_FIELDS = ["address", "city", "state", "pincode", "photoBase64"];

function toPublicUser(user) {
  return {
    id: user.id,
    name: user.name,
    mobile: user.mobile,
    address: user.address,
    city: user.city,
    state: user.state,
    pincode: user.pincode,
    photoBase64: user.photoBase64,
  };
}

router.post("/otp/request", async (req, res, next) => {
  try {
    const { mobile } = req.body || {};
    if (!mobile) {
      throw new HttpError(400, "mobile is required");
    }

    const result = await sendOtp(mobile);
    res.status(200).json({ sent: true, ...(result.devOtp ? { devOtp: result.devOtp } : {}) });
  } catch (error) {
    next(error);
  }
});

router.post("/otp/verify", async (req, res, next) => {
  try {
    const { mobile, otp } = req.body || {};
    if (!mobile || !otp) {
      throw new HttpError(400, "mobile and otp are required");
    }

    const valid = await verifyOtp(mobile, otp);
    if (!valid) {
      throw new HttpError(401, "Invalid or expired OTP");
    }

    let user = await prisma.user.findUnique({ where: { mobile } });
    const isNewUser = !user;
    if (!user) {
      user = await prisma.user.create({ data: { mobile, name: "" } });
    }

    const token = signToken(user.id);
    res.status(200).json({ token, user: toPublicUser(user), isNewUser });
  } catch (error) {
    next(error);
  }
});

router.get("/me", requireAuth, async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({ where: { id: req.userId } });
    if (!user) {
      throw new HttpError(404, "User not found");
    }
    res.status(200).json(toPublicUser(user));
  } catch (error) {
    next(error);
  }
});

router.patch("/me", requireAuth, async (req, res, next) => {
  try {
    const { name, ...rest } = req.body || {};

    if (!name) {
      throw new HttpError(400, "name is required");
    }

    const data = { name };
    for (const field of PROFILE_FIELDS) {
      if (rest[field] !== undefined) {
        data[field] = rest[field];
      }
    }

    const user = await prisma.user.update({
      where: { id: req.userId },
      data,
    });
    res.status(200).json(toPublicUser(user));
  } catch (error) {
    next(error);
  }
});

module.exports = router;
