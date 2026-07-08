# The Shoolins API contract

Base URL (dev): `http://localhost:4000/api`

## Auth (OTP-based, no passwords)
- `POST /auth/otp/request` body `{ mobile }` -> `200 { sent: true }`. In local dev, when MSG91 env vars aren't configured, the response also includes `devOtp` (the real OTP, so the app can display it for testing) and the same value is logged server-side.
- `POST /auth/otp/verify` body `{ mobile, otp }` -> `200 { token, user: { id, name, mobile }, isNewUser }` or `401 { error }`. First successful verify for an unseen mobile number auto-creates the user with `name: ""` — the client should prompt for a name via `PATCH /auth/me` when `isNewUser` is true.
- `GET /auth/me` (auth required) -> `200 { id, name, mobile, address, city, state, pincode, photoBase64 }` (the optional profile fields are `null` until set)
- `PATCH /auth/me` (auth required) body `{ name, address?, city?, state?, pincode?, photoBase64? }` -> `200 { id, name, mobile, address, city, state, pincode, photoBase64 }`. `name` is required on every call; the optional fields are only updated when present in the request body — omit a field to leave it unchanged. `photoBase64` is the raw base64-encoded image data (no `data:` URL prefix), stored as-is and returned as-is; the client renders it directly (e.g. Flutter's `Image.memory(base64Decode(...))`).

JWT sent as `Authorization: Bearer <token>` on all endpoints below.

## Products
- `GET /products?category=women|men&q=search+text&sort=price_asc|price_desc|name_asc` -> `200 [{ id, name, price, image, category }]` (all query params optional; `q` matches on name)
- `GET /products/:id` -> `200 { id, name, price, image, category }` or `404`

`image` is a bare filename (e.g. `"shirt1.png"`) — the Flutter app bundles these as local assets under `assets/products/`, the backend does not serve image files.

Seed data (6 products, ids are strings "1".."6", prices are INR):
1. Summer Dress, 1999, shirt1.png, women
2. Casual Shirt, 1499, shirt2.png, men
3. Elegant Skirt, 2499, shirt3.png, women
4. Denim Jacket, 2999, shirt4.png, men
5. Floral Blouse, 1799, shirt4.png, women
6. Formal Trousers, 2199, shirt1.png, men

## Cart (auth required)
- `GET /cart` -> `200 [{ productId, name, price, image, quantity }]`
- `POST /cart` body `{ productId, quantity? = 1 }` -> `200` updated cart array (increments quantity if item already in cart)
- `PATCH /cart/:productId` body `{ quantity }` -> `200` updated cart array (sets the absolute quantity; `quantity <= 0` removes the item)
- `DELETE /cart/:productId` -> `200` updated cart array
- `DELETE /cart` -> `204` (clear cart)

## Orders (auth required)
- `POST /orders/checkout` -> creates an order from the current cart contents, clears the cart, returns `201 { id, items: [{ productId, name, price, image, quantity }], total, createdAt }`. `400` if cart is empty.
- `GET /orders` -> `200 [{ id, items, total, createdAt }]`, most recent first

## Wishlist (auth required)
- `GET /wishlist` -> `200 [{ productId, name, price, image, category }]`, most recently added first
- `POST /wishlist` body `{ productId }` -> `200` updated wishlist array (idempotent — adding an already-wishlisted product is a no-op)
- `DELETE /wishlist/:productId` -> `200` updated wishlist array

## Errors
All error responses: `{ error: "message" }` with appropriate 4xx/5xx status.
