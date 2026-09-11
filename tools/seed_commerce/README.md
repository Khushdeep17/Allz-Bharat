# Allz Bharat - Local Commerce Data Seeder

This is an isolated, one-time local development tool to seed initial development commerce data (Categories, Shops, Products) into Google Cloud Firestore using the Firebase Admin SDK.

---

## Prerequisites

- **Node.js**: >= 18.0.0 (Node v24.x recommended)
- **Firebase Service Account Key JSON**: Generated from the Firebase Console.

---

## Security Guidelines

> [!CAUTION]
> **NEVER** copy, commit, or move your Firebase Service Account JSON key into this repository or into the Flutter app directory (`customer_app/`). Keep it safely in your user folder or Downloads directory.

---

## Setup & Dependencies

From the repository root or the `tools/seed_commerce` directory, install the required dependency:

```bash
cd tools/seed_commerce
npm install
```

---

## How to Run

### Step 1: Set `GOOGLE_APPLICATION_CREDENTIALS`

Point the standard Google credentials environment variable to the path of your downloaded JSON key:

**PowerShell (Windows):**
```powershell
$env:GOOGLE_APPLICATION_CREDENTIALS="C:\Users\<YourUsername>\Downloads\your-firebase-adminsdk-key.json"
```

**Command Prompt (cmd.exe):**
```cmd
set GOOGLE_APPLICATION_CREDENTIALS=C:\Users\<YourUsername>\Downloads\your-firebase-adminsdk-key.json
```

---

### Step 2: Test Dry Run (Safe / No Writes)

Running without the `--confirm` flag prints a safety check and does not perform any writes:

```bash
npm run seed
```

---

### Step 3: Execute Confirmed Seed

When you are ready to write the 16 commerce documents to Firestore:

```bash
npm run seed -- --confirm
```

---

## Seeded Data Summary

| Collection | Document ID | Description |
| :--- | :--- | :--- |
| **`categories`** | `cat_grocery` | Grocery (`🛒`) |
| **`categories`** | `cat_dairy` | Dairy (`🥛`) |
| **`categories`** | `cat_snacks` | Snacks (`🍪`) |
| **`categories`** | `cat_beverages` | Beverages (`🥤`) |
| **`shops`** | `shop_001` | Sharma Kirana Store (Shastri Nagar, Meerut) |
| **`shops`** | `shop_002` | Gupta General Store (Shastri Nagar, Meerut) |
| **`products`** | `prod_001` - `prod_005` | 5 items for Shop 1 (Amul Taaza, Parle-G, Tata Salt, Coke, Maggi) |
| **`products`** | `prod_006` - `prod_010` | 5 items for Shop 2 (Amul Gold, Marie Gold, Atta, Sprite, Lay's) |

---

## Verification

After executing the confirmed seed command:
1. Open the **[Firebase Console](https://console.firebase.google.com/)**.
2. Navigate to **Firestore Database** -> **Data**.
3. Verify the existence of the collections:
   - `categories` (4 documents)
   - `shops` (2 documents)
   - `products` (10 documents)
