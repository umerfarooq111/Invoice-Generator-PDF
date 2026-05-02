// ============================================================
// services/database_init.dart
// Platform-safe SQLite initialization
// Handles both mobile (Android/iOS) and desktop (Windows/Linux/macOS)
// ============================================================

import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initialize the database factory for the current platform.
/// On Android/iOS, sqflite works natively — no setup needed.
/// On desktop, we must use sqflite_common_ffi.
void initializeDatabaseFactory() {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Android and iOS use sqflite natively — nothing to do
}
