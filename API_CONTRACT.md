# The Shoolins API contract

Base URL (dev): `http://localhost:4000/api`

## Auth (OTP-based, no passwords)
- `POST /auth/otp/request` body `{ mobile }` -> `200 { sent: true }`. In local dev, when MSG91 env vars aren't configured, the response also includes `devOtp` (the real OTP, so the app can display it for testing) and the same value is logged server-side.
- `POST /auth/otp/verify` body `{ mobile, otp }` -> `200 { token, user: { id, name, mobile }, isNewUser }` or `401 { error }`. First successful verify for an unseen mobile number auto-creates the user with `name: ""` — the client should prompt for a name via `PATCH /auth/me` when `isNewUser` is true.
- `GET /auth/me` (auth required) -> `200 { id, name, mobile, address, city, state, pincode, photoBase64 }` (the optional profile fields are `null` until set)
- `PATCH /auth/me` (auth required) body `{ name, address?, city?, state?, pincode?, photoBase64? }` -> `200 { id, name, mobile, address, city, state, pincode, photoBase64 }`. `name` is required on every call; the optional fields are only updated when present in the request body — omit a field to leave it unchanged. `photoBase64` is the raw base64-encoded image data (no `data:` URL prefix), stored as-is and returned as-is; the client renders it directly (e.g. Flutter's `Image.memory(base64Decode(...))`).

JWT sent as `Authorization: Bearer <token>` on all endpoints below.

## Products
- `GET /products?category=women|men&q=search+text&sort=price_asc|price_desc|name_asc` -> `200 [{ id, name, price, image, imageBase64, imagesBase64, category }]` (all query params optional; `q` matches on name)
- `GET /products/:id` -> `200 { id, name, price, image, imageBase64, imagesBase64, category }` or `404`

`image` is a bare filename (e.g. `"shirt1.png"`) for the original seeded catalog — the Flutter app bundles these as local assets under `assets/products/`. Products created via the admin panel instead carry their photo in `imageBase64` (raw base64, no `data:` prefix) with `image` left as `""`; the client renders `imageBase64` when present, falling back to the bundled asset otherwise.

`imagesBase64` is an array of additional gallery photos beyond the cover (`image`/`imageBase64`) — always `[]` unless the admin uploaded extra photos. Only the product detail screen's scrolling carousel uses it; cards, cart, wishlist, and order history all show just the cover photo.

Seed data (6 products, ids are strings "1".."6", prices are INR):
1. Summer Dress, 1999, shirt1.png, women
2. Casual Shirt, 1499, shirt2.png, men
3. Elegant Skirt, 2499, shirt3.png, women
4. Denim Jacket, 2999, shirt4.png, men
5. Floral Blouse, 1799, shirt4.png, women
6. Formal Trousers, 2199, shirt1.png, men

## Cart (auth required)
- `GET /cart` -> `200 [{ productId, name, price, image, imageBase64, quantity }]`
- `POST /cart` body `{ productId, quantity? = 1 }` -> `200` updated cart array (increments quantity if item already in cart; atomic upsert)
- `PATCH /cart/:productId` body `{ quantity }` -> `200` updated cart array (sets the absolute quantity; `quantity <= 0` removes the item)
- `DELETE /cart/:productId` -> `200` updated cart array
- `DELETE /cart` -> `204` (clear cart)

## Orders (auth required)
- `POST /orders/checkout` -> creates an order from the current cart contents, clears the cart, returns `201 { id, items: [{ productId, name, price, image, imageBase64, quantity }], total, createdAt }`. `400` if cart is empty.
- `GET /orders` -> `200 [{ id, items, total, createdAt }]`, most recent first

## Wishlist (auth required)
- `GET /wishlist` -> `200 [{ productId, name, price, image, imageBase64, category }]`, most recently added first
- `POST /wishlist` body `{ productId }` -> `200` updated wishlist array (idempotent — adding an already-wishlisted product is a no-op)
- `DELETE /wishlist/:productId` -> `200` updated wishlist array

## Admin (product management)
A minimal password-protected web UI lives at `/admin` (static page, not under `/api`). It calls these endpoints:
- `POST /admin/login` body `{ password }` -> `200 { token }` (checked against `ADMIN_PASSWORD` env var) or `401`. Token carries `{ role: "admin" }`, expires in 12h.
- Admin token sent as `Authorization: Bearer <token>` on all endpoints below; `401`/`403` if missing/invalid/not an admin token.
- `GET /admin/products` -> `200 [{ id, name, price, image, imageBase64, imagesBase64, category }]`
- `POST /admin/products` body `{ name, price, category, imageBase64, imagesBase64? }` -> `201` created product. `category` must be `men` or `women`. `imagesBase64` (if present) must be an array of base64 strings.
- `PATCH /admin/products/:id` body any subset of `{ name, price, category, imageBase64, imagesBase64 }` -> `200` updated product, or `404`.
- `DELETE /admin/products/:id` -> `204`, or `404`. Cascades to any existing cart/wishlist rows referencing it.

## Errors
All error responses: `{ error: "message" }` with appropriate 4xx/5xx status.
