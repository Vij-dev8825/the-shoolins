function notFoundHandler(req, res) {
  res.status(404).json({ error: "Not found" });
}

function errorHandler(err, req, res, next) {
  console.error(err);
  const status = err.status || 500;
  const message = err.expose ? err.message : status < 500 ? err.message : "Internal server error";
  res.status(status).json({ error: message || "Internal server error" });
}

module.exports = { notFoundHandler, errorHandler };
