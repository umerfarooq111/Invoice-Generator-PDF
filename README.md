# ⚡ QuickBill PK

> **QuickBill PK** is a modern, offline-first Invoice Generator and Business Analytics app built for small businesses, shop owners, and freelancers. It empowers merchants to manage products, maintain customer lists, track sales performance, and generate professional PDF invoices directly from their devices—no internet or account required.

---

## 🎯 Purpose & Vision

In emerging markets like Pakistan, small-to-medium retail shops and freelancers often face a dilemma: use manual, error-prone paper invoice receipts, or pay expensive monthly subscriptions for complex cloud-based billing systems. 

**QuickBill PK** was created to bridge this gap. It provides a **100% free, secure, and offline billing solution** that runs fast on mobile and desktop. By keeping all data locally on the user's device, it ensures absolute privacy and zero latency.

---

## ⚡ Why It's Different (Key Differentiators)

Unlike standard invoice templates or bulky cloud software, QuickBill PK stands out in several key areas:

*   **🔒 Absolute Data Privacy & Offline-First:** No accounts, no sign-ups, and no cloud servers. All inventory, customer records, and invoice data reside in a secure local SQLite database on *your* device.
*   **🇵🇰 Tailored for Pakistan (PKR):** Fully localized for PKR (Rupees) currency formatting, custom shop profiles (address, phone numbers), and terms/conditions relevant to local market needs.
*   **📱 Shared in Seconds via WhatsApp:** Seamless integration with the system share sheet allows you to send PDF invoices to customers via WhatsApp, email, or SMS in just one tap.
*   **📊 Dynamic Sales Reports & Charts:** Built-in dashboard and interactive reports screen powered by `fl_chart` visually displays sales trends, total invoices, and performance metrics.
*   **💻 Cross-Platform Adaptability:** Powered by Flutter and SQLite FFI, the app is architected to support both mobile (Android/iOS) and desktop (Windows/macOS) devices with a unified codebase.

---

## ✨ Features

*   **📦 Product & Inventory Registry:** Add, update, and manage your inventory with tracking for unit prices, descriptions, and stock counts.
*   **👥 Customer Directory:** Store client names and contact numbers for quick billing selection.
*   **✍️ Dynamic Invoice Creator:** Create custom invoices on the go. Includes an interactive product selector and quantity stepper with real-time total calculations.
*   **📄 Professional PDF Engine:** Automatically compile invoices into elegant, print-ready PDF formats.
*   **👁️ Built-in PDF Preview:** Preview your invoice directly in the app before sharing or printing.
*   **📈 Dashboard & Analytics:** High-level dashboard showcasing total sales, invoice counts, and detailed charts summarizing store metrics.
*   **⚙️ Custom Shop Profile:** Save store settings (Name, Address, Phone, Default Terms & Conditions, Currency Symbol) to auto-fill every invoice.

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
│   ├── invoice_item.dart        ← Invoice line item model
│   └── shop_settings.dart       ← Shop configurations & defaults
│
├── services/
│   ├── database_service.dart    ← SQLite CRUD (singleton)
│   └── pdf_service.dart         ← PDF generation & sharing
│
├── providers/
│   ├── product_provider.dart    ← Product state management
│   ├── customer_provider.dart   ← Customer state management
│   ├── settings_provider.dart   ← Shop settings state management
│   └── invoice_provider.dart    ← Invoice state + PDF trigger
│
├── screens/
│   ├── home_screen.dart         ← Dashboard (stats + recent invoices)
│   ├── invoice_detail_screen.dart ← Detail view + PDF preview
│   ├── reports_screen.dart      ← Visual charts and sales trends
│   ├── settings_screen.dart     ← Shop details, defaults & preferences
│   ├── customers/
│   │   ├── customers_screen.dart
│   │   └── add_edit_customer_screen.dart
│   ├── products/
│   │   ├── products_screen.dart
│   │   └── add_edit_product_screen.dart
│   └── invoices/
│       ├── create_invoice_screen.dart
│       └── invoice_history_screen.dart
│
└── widgets/
    └── common_widgets.dart      ← Reusable UI components
```

---

## ⚙️ Setup & Installation

Follow these steps to run the application on your local machine.

### Prerequisites

Before running this app, ensure you have Flutter installed:
1. Download Flutter SDK from [Flutter Official Website](https://docs.flutter.dev/get-started/install/windows)
2. Extract the package (e.g., to `C:\src\flutter`)
3. Add `C:\src\flutter\bin` to your system PATH
4. Run `flutter doctor` in your terminal to verify the setup

---

### Run Instructions

#### Step 1 — Initialize the Flutter project

Open a terminal (PowerShell or CMD) in the `InvoiceAppFlutter` directory and run:

```bash
# This creates all the Flutter scaffolding (gradle, MainActivity, etc.)
flutter create . --org com.quickbillpk --project-name quickbill_pk
```

> ⚠️ **IMPORTANT:** When prompted `"Do you want to overwrite pubspec.yaml?"`, type **n** (no) to preserve custom dependencies.

#### Step 2 — Install dependencies

Fetch all the required packages:
```bash
flutter pub get
```

#### Step 3 — Launch the app

Run the app on a connected emulator, physical device, or desktop environment:
```bash
# Run on an Android emulator or connected device
flutter run

# Build a release APK
flutter build apk --release
```

---

## 📦 Core Dependencies Used

| Package | Purpose |
|---------|---------|
| `provider ^6.1.1` | State management |
| `sqflite ^2.3.3` | Local SQLite database |
| `sqflite_common_ffi ^2.3.3` | Desktop SQLite database support |
| `pdf ^3.10.8` | PDF generation |
| `printing ^5.12.0` | In-app PDF preview, printing, & sharing |
| `intl ^0.19.0` | Date, currency, and number formatting |
| `uuid ^4.4.0` | Unique ID generation |
| `fl_chart ^0.66.2` | Interactive sales charts and reports |

---

## 🔧 Troubleshooting

*   **App crashes when sharing a PDF?**
    *   Ensure that storage and sharing permissions are configured properly in `AndroidManifest.xml` (the app includes default configurations, but verifying OS-level permission popup approval is recommended).
*   **Invoices or reports not updating?**
    *   Pull down on the dashboard or history screens to force a database reload.
*   **`flutter: command not found` error?**
    *   Add Flutter to your system PATH environment variable:
        ```powershell
        setx PATH "%PATH%;C:\src\flutter\bin"
        ```
