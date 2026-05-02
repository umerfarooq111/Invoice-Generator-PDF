// ============================================================
// main.dart - App Entry Point
// Sets up MultiProvider and the main MaterialApp with bottom nav
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/product_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/invoice_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/products/products_screen.dart';
import 'screens/customers/customers_screen.dart';
import 'screens/invoices/invoice_history_screen.dart';
import 'screens/settings_screen.dart';
import 'services/database_init.dart';

void main() {
  // Ensure Flutter engine is initialized before running app
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize sqflite for the current platform
  initializeDatabaseFactory();

  runApp(const QuickBillApp());
}

class QuickBillApp extends StatelessWidget {
  const QuickBillApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Register all providers so they are available throughout the app
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => InvoiceProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'QuickBill PK',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const MainNavigation(),
      ),
    );
  }

  /// Defines the app's visual theme — clean blue & white color palette
  ThemeData _buildTheme() {
    const primaryColor = Color(0xFF1565C0); // Deep blue
    const accentColor = Color(0xFF42A5F5);  // Light blue

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',

      // AppBar style
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Elevated button style — large, easy to tap
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),

      // FloatingActionButton style
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),

      // Card style
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ============================================================
// MainNavigation - Bottom Navigation Bar Controller
// Manages which screen is currently visible
// ============================================================
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  // Index of the currently selected tab
  int _selectedIndex = 0;

  // List of screens corresponding to each bottom nav tab
  final List<Widget> _screens = const [
    HomeScreen(),
    ProductsScreen(),
    CustomersScreen(),
    InvoiceHistoryScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Show the currently selected screen
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // Bottom navigation bar with 4 tabs
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Invoices',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
