# Allz Bharat

Hyperlocal commerce platform connecting customers
with trusted neighborhood stores.

## Current Status

- **customer_app**: Flutter app with a working dummy UI (Splash → Onboarding → Home) using mock data.
- **Backend / Firebase**: No integration yet.
- **merchant_app / rider app**: Not started yet.

## Tech Stack

- **Mobile**: Flutter / Dart
- **AI Dev Environment**: Google Antigravity
- **Backend**: Firebase *(planned)*
- **Payments**: Cashfree *(planned)*

## Apps

- Customer (`customer_app/`)
- Merchant *(planned)*
- Rider *(planned)*

## Backend

Firebase *(planned)*

## Web

Next.js *(planned)*

## Project Structure

Inside `customer_app/`:
- `lib/core/` — App constants, theme, typography, routing, and global mock data.
- `lib/features/` — Feature modules (Splash, Onboarding, Home) with presentation and feature-specific models/widgets.
- `lib/shared/` — Reusable shared UI widgets across features.

## How to Run

```bash
cd customer_app
flutter pub get
flutter run
```