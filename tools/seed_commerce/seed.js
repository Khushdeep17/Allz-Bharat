/**
 * Allz Bharat - Local Commerce Data Seeder
 *
 * This script is a ONE-TIME local development tool to seed initial Firestore
 * commerce collections (categories, shops, products) using the Firebase Admin SDK.
 *
 * Safety Rules:
 * 1. Requires explicit `--confirm` flag to execute writes.
 * 2. Uses GOOGLE_APPLICATION_CREDENTIALS environment variable for authentication.
 * 3. Uses deterministic document IDs and batch writes for idempotency.
 */

const fs = require('fs');
const path = require('path');

// 1. Check for explicit confirmation flag
const isConfirmed = process.argv.includes('--confirm');

if (!isConfirmed) {
  console.log('\n===============================================================');
  console.log('                 ALLZ BHARAT SEED TOOL (DRY RUN)              ');
  console.log('===============================================================');
  console.log('SAFETY CHECK: No write operations performed.');
  console.log('\nThis seed tool is prepared to write 16 commerce documents:');
  console.log('  - 4 Categories (categories/{categoryId})');
  console.log('  - 2 Shops (shops/{shopId})');
  console.log('  - 10 Products (products/{productId})');
  console.log('\nTo execute actual Firestore writes, ensure GOOGLE_APPLICATION_CREDENTIALS');
  console.log('is set, then run with the --confirm flag:');
  console.log('\n  npm run seed -- --confirm');
  console.log('===============================================================\n');
  process.exit(0);
}

// 2. Validate Google Application Credentials
const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (!credPath) {
  console.error('\n[ERROR] GOOGLE_APPLICATION_CREDENTIALS environment variable is not set.');
  console.error('Please set it to the path of your downloaded Firebase Service Account JSON key.');
  console.error('\nExample (PowerShell):');
  console.error('  $env:GOOGLE_APPLICATION_CREDENTIALS="C:\\Users\\<Username>\\Downloads\\your-service-account-key.json"');
  console.error('\nExample (Command Prompt):');
  console.error('  set GOOGLE_APPLICATION_CREDENTIALS=C:\\Users\\<Username>\\Downloads\\your-service-account-key.json\n');
  process.exit(1);
}

if (!fs.existsSync(credPath)) {
  console.error(`\n[ERROR] Service account key file not found at: ${credPath}`);
  console.error('Please verify the path and try again.\n');
  process.exit(1);
}

// 3. Initialize Firebase Admin SDK
const admin = require('firebase-admin');

try {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
} catch (error) {
  console.error('\n[ERROR] Failed to initialize Firebase Admin SDK:', error.message);
  process.exit(1);
}

const db = admin.firestore();

// 4. Define Seed Data Payloads
const categories = [
  { id: 'cat_grocery', name: 'Grocery', icon: '🛒', isActive: true },
  { id: 'cat_dairy', name: 'Dairy', icon: '🥛', isActive: true },
  { id: 'cat_snacks', name: 'Snacks', icon: '🍪', isActive: true },
  { id: 'cat_beverages', name: 'Beverages', icon: '🥤', isActive: true },
];

const shops = [
  {
    id: 'shop_001',
    name: 'Sharma Kirana Store',
    address: 'Shastri Nagar, Meerut',
    imageUrl: '',
    rating: 4.2,
    isOpen: true,
    isActive: true,
  },
  {
    id: 'shop_002',
    name: 'Gupta General Store',
    address: 'Shastri Nagar, Meerut',
    imageUrl: '',
    rating: 4.5,
    isOpen: true,
    isActive: true,
  },
];

const products = [
  // Shop 1 (shop_001)
  {
    id: 'prod_001',
    shopId: 'shop_001',
    categoryId: 'cat_dairy',
    name: 'Amul Taaza Milk 500ml',
    description: 'Fresh Amul Taaza milk 500ml pack',
    price: 28,
    imageUrl: '',
    inStock: true,
    isActive: true,
  },
  {
    id: 'prod_002',
    shopId: 'shop_001',
    categoryId: 'cat_snacks',
    name: 'Parle-G Biscuit 100g',
    description: 'Classic Parle-G glucose biscuits',
    price: 10,
    imageUrl: '',
    inStock: true,
    isActive: true,
  },
  {
    id: 'prod_003',
    shopId: 'shop_001',
    categoryId: 'cat_grocery',
    name: 'Tata Salt 1kg',
    description: 'Tata iodised salt 1kg pack',
    price: 22,
    imageUrl: '',
    inStock: true,
    isActive: true,
  },
  {
    id: 'prod_004',
    shopId: 'shop_001',
    categoryId: 'cat_beverages',
    name: 'Coca-Cola 750ml',
    description: 'Coca-Cola soft drink 750ml bottle',
    price: 40,
    imageUrl: '',
    inStock: true,
    isActive: true,
  },
  {
    id: 'prod_005',
    shopId: 'shop_001',
    categoryId: 'cat_snacks',
    name: 'Maggi Noodles 70g',
    description: 'Maggi instant noodles 70g pack',
    price: 14,
    imageUrl: '',
    inStock: false,
    isActive: true,
  },
  // Shop 2 (shop_002)
  {
    id: 'prod_006',
    shopId: 'shop_002',
    categoryId: 'cat_dairy',
    name: 'Amul Gold Milk 500ml',
    description: 'Amul Gold milk 500ml pack',
    price: 32,
    imageUrl: '',
    inStock: true,
    isActive: true,
  },
  {
    id: 'prod_007',
    shopId: 'shop_002',
    categoryId: 'cat_snacks',
    name: 'Britannia Marie Gold 100g',
    description: 'Britannia Marie Gold biscuits',
    price: 20,
    imageUrl: '',
    inStock: true,
    isActive: true,
  },
  {
    id: 'prod_008',
    shopId: 'shop_002',
    categoryId: 'cat_grocery',
    name: 'Aashirvaad Atta 5kg',
    description: 'Aashirvaad whole wheat atta 5kg',
    price: 250,
    imageUrl: '',
    inStock: true,
    isActive: true,
  },
  {
    id: 'prod_009',
    shopId: 'shop_002',
    categoryId: 'cat_beverages',
    name: 'Sprite 750ml',
    description: 'Sprite soft drink 750ml bottle',
    price: 40,
    imageUrl: '',
    inStock: true,
    isActive: true,
  },
  {
    id: 'prod_010',
    shopId: 'shop_002',
    categoryId: 'cat_snacks',
    name: "Lay's Chips 52g",
    description: "Lay's potato chips 52g pack",
    price: 20,
    imageUrl: '',
    inStock: true,
    isActive: true,
  },
];

// 5. Execute Batch Seed
async function seedDatabase() {
  console.log('\n[START] Seeding Firestore commerce collections...');
  const batch = db.batch();
  const serverTimestamp = admin.firestore.FieldValue.serverTimestamp();

  // Categories
  for (const cat of categories) {
    const docRef = db.collection('categories').doc(cat.id);
    batch.set(docRef, { ...cat }, { merge: true });
    console.log(`  + Queued Category: categories/${cat.id} (${cat.name})`);
  }

  // Shops
  for (const shop of shops) {
    const docRef = db.collection('shops').doc(shop.id);
    batch.set(
      docRef,
      {
        ...shop,
        createdAt: serverTimestamp,
      },
      { merge: true }
    );
    console.log(`  + Queued Shop: shops/${shop.id} (${shop.name})`);
  }

  // Products
  for (const prod of products) {
    const docRef = db.collection('products').doc(prod.id);
    batch.set(
      docRef,
      {
        ...prod,
        createdAt: serverTimestamp,
      },
      { merge: true }
    );
    console.log(`  + Queued Product: products/${prod.id} (${prod.name})`);
  }

  console.log('\n[COMMITTING] Writing batch to Firestore...');
  await batch.commit();
  console.log('[SUCCESS] Successfully seeded 16 commerce documents into Firestore!\n');
}

seedDatabase()
  .then(() => process.exit(0))
  .catch((err) => {
    console.error('\n[ERROR] Seeding failed:', err);
    process.exit(1);
  });
