# The Shoolins — Backend

Node.js + Express + Prisma (PostgreSQL) API for The Shoolins e-commerce demo. See `../API_CONTRACT.md` for the full endpoint spec.

## Setup

```bash
npm install
cp .env.example .env
# edit .env: paste your DATABASE_URL (Neon/Supabase), set a JWT_SECRET
npm run prisma:migrate
npm run prisma:seed
npm run dev
```

Server listens on `http://localhost:4000` (override with `PORT` in `.env`).

## Scripts

- `npm run dev` — start with nodemon (auto-restart)
- `npm start` — start normally
- `npm run prisma:generate` — regenerate the Prisma client
- `npm run prisma:migrate` — run `prisma migrate dev` (creates/applies migrations)
- `npm run prisma:seed` — run `prisma db seed` (inserts the 6 seed products)

## Endpoints

### Register

```bash
curl -X POST http://localhost:4000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Ada Lovelace","mobile":"9999999999","password":"secret123"}'
```

### Login

```bash
curl -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"mobile":"9999999999","password":"secret123"}'
```

### List products (optionally filter by category)

```bash
curl http://localhost:4000/api/products
curl http://localhost:4000/api/products?category=women
```

### Get a single product

```bash
curl http://localhost:4000/api/products/1
```

### View cart

```bash
curl http://localhost:4000/api/cart \
  -H "Authorization: Bearer <token>"
```

### Add to cart (increments quantity if already present)

```bash
curl -X POST http://localhost:4000/api/cart \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"productId":"1","quantity":1}'
```

### Remove one product from cart

```bash
curl -X DELETE http://localhost:4000/api/cart/1 \
  -H "Authorization: Bearer <token>"
```

### Clear cart

```bash
curl -X DELETE http://localhost:4000/api/cart \
  -H "Authorization: Bearer <token>"
```

### Checkout

```bash
curl -X POST http://localhost:4000/api/orders/checkout \
  -H "Authorization: Bearer <token>"
```

### List orders (most recent first)

```bash
curl http://localhost:4000/api/orders \
  -H "Authorization: Bearer <token>"
```
