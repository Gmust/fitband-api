// Simple script to wait for database to be ready
const { PrismaClient } = require('@prisma/client');

const prisma = new PrismaClient();

async function waitForDatabase() {
  const maxRetries = 30;
  const retryDelay = 2000; // 2 seconds

  for (let i = 0; i < maxRetries; i++) {
    try {
      await prisma.$connect();
      console.log('Database connected successfully!');
      await prisma.$disconnect();
      process.exit(0);
    } catch (error) {
      const retriesLeft = maxRetries - i - 1;
      if (retriesLeft > 0) {
        console.log(`Database connection failed. Retrying... (${retriesLeft} retries left)`);
        await new Promise(resolve => setTimeout(resolve, retryDelay));
      } else {
        console.error('ERROR: Could not connect to database after', maxRetries * retryDelay / 1000, 'seconds');
        console.error('Error:', error.message);
        await prisma.$disconnect();
        process.exit(1);
      }
    }
  }
}

waitForDatabase();

