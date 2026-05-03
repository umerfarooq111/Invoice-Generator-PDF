import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'dart:io' show Platform;

/// Initialize the database factory for the current platform.
/// On Android/iOS, sqflite works natively — no setup needed.
/// On desktop, we use sqflite_common_ffi.
/// On web, we use sqflite_common_ffi_web.
void initializeDatabaseFactory() {
  if (kIsWeb) {
    // Web support
    databaseFactory = databaseFactoryFfiWeb;
  } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    // Desktop support
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // Android and iOS use sqflite natively — nothing to do
}
