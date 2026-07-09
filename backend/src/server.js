require("dotenv").config();
const app = require("./app");
const prisma = require("./lib/prisma");

const PORT = process.env.PORT || 4000;

// Prisma connects lazily on its first query by default. On Render's free
// tier the service (and Neon's free-tier database, which also auto-suspends)
// both cold-start from idle, so the very first real request could race an
// unwarmed DB connection and 500. Connecting eagerly with retries here means
// the port only opens once the DB is confirmed reachable.
async function connectWithRetry(maxAttempts = 5) {
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      await prisma.$connect();
      return;
    } catch (error) {
      console.error(`Database connection attempt ${attempt}/${maxAttempts} failed:`, error.message);
      if (attempt === maxAttempts) throw error;
      await new Promise((resolve) => setTimeout(resolve, 1500 * attempt));
    }
  }
}

connectWithRetry()
  .then(() => {
    app.listen(PORT, () => {
      console.log(`The Shoolins backend listening on port ${PORT}`);
    });
  })
  .catch((error) => {
    console.error("Failed to connect to the database, exiting:", error);
    process.exit(1);
  });
