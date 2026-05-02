// ============================================================
// screens/settings_screen.dart
// Settings screen — manage shop info, defaults, and preferences
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shop_settings.dart';
import 'package:quickbill_pk/providers/settings_provider.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text controllers for each setting field
  late final TextEditingController _shopNameCtrl;
  late final TextEditingController _shopAddressCtrl;
  late final TextEditingController _shopPhoneCtrl;
  late final TextEditingController _shopEmailCtrl;
  late final TextEditingController _defaultTermsCtrl;
  late final TextEditingController _defaultNotesCtrl;
  late final TextEditingController _currencyCtrl;

  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with current settings
    final settings = context.read<SettingsProvider>().settings;
    _shopNameCtrl = TextEditingController(text: settings.shopName);
    _shopAddressCtrl = TextEditingController(text: settings.shopAddress);
    _shopPhoneCtrl = TextEditingController(text: settings.shopPhone);
    _shopEmailCtrl = TextEditingController(text: settings.shopEmail);
    _defaultTermsCtrl = TextEditingController(text: settings.defaultTerms);
    _defaultNotesCtrl = TextEditingController(text: settings.defaultNotes);
    _currencyCtrl = TextEditingController(text: settings.currencySymbol);

    // Track changes
    for (final ctrl in _allControllers) {
      ctrl.addListener(_onFieldChanged);
    }
  }

  List<TextEditingController> get _allControllers => [
        _shopNameCtrl,
        _shopAddressCtrl,
        _shopPhoneCtrl,
        _shopEmailCtrl,
        _defaultTermsCtrl,
        _defaultNotesCtrl,
        _currencyCtrl,
      ];

  void _onFieldChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  @override
  void dispose() {
    for (final ctrl in _allControllers) {
      ctrl.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_hasChanges)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: const Icon(Icons.save_outlined, color: Colors.white),
              label: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            // ── Shop Info Header ────────────────────────
            _SettingsHeader(
              icon: Icons.store_outlined,
              title: 'Shop Information',
              subtitle:
                  'This info will appear on your invoices and PDF headers',
              color: primary,
            ),

            // Shop Name
            _SettingsField(
              controller: _shopNameCtrl,
              label: 'Shop / Business Name',
              hint: 'e.g. "Ali General Store"',
              icon: Icons.storefront_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter your shop name';
                }
                return null;
              },
            ),

            // Shop Address
            _SettingsField(
              controller: _shopAddressCtrl,
              label: 'Shop Address',
              hint: 'e.g. "Shop #5, Main Bazar, Lahore"',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),

            // Shop Phone
            _SettingsField(
              controller: _shopPhoneCtrl,
              label: 'Phone Number',
              hint: 'e.g. "0300-1234567"',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),

            // Shop Email
            _SettingsField(
              controller: _shopEmailCtrl,
              label: 'Email (optional)',
              hint: 'e.g. "info@alishop.com"',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 8),

            // ── Currency ────────────────────────────────
            _SettingsHeader(
              icon: Icons.monetization_on_outlined,
              title: 'Currency',
              subtitle: 'Symbol used in invoices and product prices',
              color: Colors.green.shade700,
            ),

            _SettingsField(
              controller: _currencyCtrl,
              label: 'Currency Symbol',
              hint: 'e.g. "PKR", "Rs", "USD"',
              icon: Icons.attach_money_outlined,
            ),

            const SizedBox(height: 8),

            // ── Default Invoice Values ──────────────────
            _SettingsHeader(
              icon: Icons.description_outlined,
              title: 'Default Invoice Values',
              subtitle:
                  'These will auto-fill when creating new invoices',
              color: Colors.orange.shade700,
            ),

            // Default Terms & Conditions
            _SettingsField(
              controller: _defaultTermsCtrl,
              label: 'Default Terms & Conditions',
              hint:
                  'e.g. "No returns after 3 days. Warranty void if seal broken."',
              icon: Icons.gavel_outlined,
              maxLines: 3,
            ),

            // Default Notes
            _SettingsField(
              controller: _defaultNotesCtrl,
              label: 'Default Notes / Messages',
              hint:
                  'e.g. "Payment due within 7 days. Thank you for your business!"',
              icon: Icons.sticky_note_2_outlined,
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // ── Save Button ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveSettings,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Settings',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── App Info ────────────────────────────────
            Center(
              child: Column(
                children: [
                  Icon(Icons.bolt, color: primary, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    'QuickBill PK',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primary,
                      fontSize: 16,
                    ),
                  ),
                  const Text(
                    'Version 1.1.0',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Simple Invoice Generator for Pakistan',
                    style: TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Save all settings to the database
  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newSettings = ShopSettings(
      shopName: _shopNameCtrl.text.trim(),
      shopAddress: _shopAddressCtrl.text.trim(),
      shopPhone: _shopPhoneCtrl.text.trim(),
      shopEmail: _shopEmailCtrl.text.trim(),
      defaultTerms: _defaultTermsCtrl.text.trim(),
      defaultNotes: _defaultNotesCtrl.text.trim(),
      currencySymbol: _currencyCtrl.text.trim().isNotEmpty
          ? _currencyCtrl.text.trim()
          : 'PKR',
    );

    final provider = context.read<SettingsProvider>();
    final success = await provider.saveSettings(newSettings);

    if (!mounted) return;

    if (success) {
      setState(() {
        _hasChanges = false;
        _isSaving = false;
      });
      showSuccessSnackBar(context, 'Settings saved successfully!');
    } else {
      setState(() => _isSaving = false);
      showErrorSnackBar(context, provider.error ?? 'Failed to save settings');
    }
  }
}

// ─── Settings Header Widget ───────────────────────────────

class _SettingsHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _SettingsHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Settings Text Field Widget ───────────────────────────

class _SettingsField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  const _SettingsField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ),
    );
  }
}
