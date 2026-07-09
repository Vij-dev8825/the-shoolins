const jwt = require("jsonwebtoken");
const prisma = require("../lib/prisma");

async function requireAuth(req, res, next) {
  const header = req.headers.authorization || "";
  const [scheme, token] = header.split(" ");

  if (scheme !== "Bearer" || !token) {
    return res.status(401).json({ error: "Missing or invalid Authorization header" });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);

    // A valid signature only proves the token was issued by us at some
    // point — the user it points to may no longer exist (e.g. the database
    // was reset/migrated since the token was issued). Routes that write
    // data keyed on userId would otherwise hit a foreign key constraint
    // violation instead of a clean 401.
    const user = await prisma.user.findUnique({ where: { id: payload.userId } });
    if (!user) {
      return res.status(401).json({ error: "Invalid or expired token" });
    }

    req.userId = payload.userId;
    next();
  } catch (error) {
    return res.status(401).json({ error: "Invalid or expired token" });
  }
}

module.exports = requireAuth;
