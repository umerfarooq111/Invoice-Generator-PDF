# QuickBill PK — Setup Guide

## ⚙️ Prerequisites

Before running this app, make sure you have Flutter installed:
1. Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\src\flutter`
3. Add `C:\src\flutter\bin` to your system PATH
4. Run `flutter doctor` to verify

---

## 🚀 How to Run

### Step 1 — Initialize the Flutter project

Open a terminal (PowerShell or CMD) in the `InvoiceAppFlutter` folder and run:

```bash
# This creates all the Flutter scaffolding (gradle, MainActivity, etc.)
flutter create . --org com.quickbillpk --project-name quickbill_pk
```

> ⚠️ When asked "Do you want to overwrite pubspec.yaml?", type **n** (no) to keep our custom dependencies.

### Step 2 — Install dependencies

```bash
flutter pub get
```

### Step 3 — Run the app

```bash
# On Android emulator or connected device
flutter run

# Or build an APK
flutter build apk --release
```

---

## 📁 Project Structure

```
lib/
├── main.dart                    ← App entry, Provider setup, bottom nav
│
├── models/
│   ├── product.dart             ← Product data model
│   ├── customer.dart            ← Customer data model
│   ├── invoice.dart             ← Invoice header model
│   └── invoice_item.dart        ← Invoice line item model
│
├── services/
│   ├── database_service.dart    ← SQLite CRUD (singleton)
│   └── pdf_service.dart         ← PDF generation & sharing
│
├── providers/
│   ├── product_provider.dart    ← Product state management
│   ├── customer_provider.dart   ← Customer state management
│   └── invoice_provider.dart    ← Invoice state + PDF trigger
│
├── screens/
│   ├── home_screen.dart         ← Dashboard (stats + recent invoices)
│   ├── invoice_detail_screen.dart
│   ├── products/
│   │   ├── products_screen.dart
│   │   └── add_edit_product_screen.dart
│   ├── customers/
│   │   ├── customers_screen.dart
│   │   └── add_edit_customer_screen.dart
│   └── invoices/
│       ├── create_invoice_screen.dart
│       └── invoice_history_screen.dart
│
└── widgets/
    └── common_widgets.dart      ← Reusable UI components
```

---

## 📦 Dependencies Used

| Package | Purpose |
|---------|---------|
| `provider ^6.1.1` | State management |
| `sqflite ^2.3.3` | Local SQLite database |
| `path ^1.9.0` | DB file path resolution |
| `pdf ^3.10.8` | PDF generation |
| `printing ^5.12.0` | PDF preview & sharing |
| `intl ^0.19.0` | Date & currency formatting |
| `uuid ^4.4.0` | Unique ID generation |

---

## ✨ Features

- ✅ Add / Edit / Delete **Products** (name, price, stock)
- ✅ Add / Edit / Delete **Customers** (name, phone)
- ✅ Create **Invoices** by selecting customer + adding multiple products
- ✅ Live total calculation with **quantity stepper**
- ✅ **Save invoices** to local SQLite database (fully offline)
- ✅ **Generate PDF** invoices with professional formatting
- ✅ **Share PDF** via system share sheet (WhatsApp, email, etc.)
- ✅ **Preview PDF** in built-in viewer
- ✅ Dashboard with **total sales** and **invoice count**
- ✅ **Invoice history** with delete and share options

---

## 🔧 Troubleshooting

**App crashes on PDF share?**
→ Make sure you have storage permissions in `AndroidManifest.xml` (already included)

**Invoices not loading?**
→ Pull down to refresh on any list screen

**flutter: command not found?**
→ Add Flutter to PATH: `setx PATH "%PATH%;C:\src\flutter\bin"`

