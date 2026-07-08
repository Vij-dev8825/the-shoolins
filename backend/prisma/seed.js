const { PrismaClient } = require("@prisma/client");

const prisma = new PrismaClient();

const products = [
  { id: "1", name: "Summer Dress", price: 1999, image: "shirt1.png", category: "women" },
  { id: "2", name: "Casual Shirt", price: 1499, image: "shirt2.png", category: "men" },
  { id: "3", name: "Elegant Skirt", price: 2499, image: "shirt3.png", category: "women" },
  { id: "4", name: "Denim Jacket", price: 2999, image: "shirt4.png", category: "men" },
  { id: "5", name: "Floral Blouse", price: 1799, image: "shirt4.png", category: "women" },
  { id: "6", name: "Formal Trousers", price: 2199, image: "shirt1.png", category: "men" },
];

async function main() {
  for (const product of products) {
    await prisma.product.upsert({
      where: { id: product.id },
      update: product,
      create: product,
    });
  }
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (error) => {
    console.error(error);
    await prisma.$disconnect();
    process.exit(1);
  });
