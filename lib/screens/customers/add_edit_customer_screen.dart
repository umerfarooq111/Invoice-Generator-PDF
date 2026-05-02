// ============================================================
// screens/customers/add_edit_customer_screen.dart
// Form screen to add a new customer or edit an existing one
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/common_widgets.dart';

class AddEditCustomerScreen extends StatefulWidget {
  /// If [customer] is provided, we are editing; otherwise adding
  final Customer? customer;

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isSaving = false;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.customer!.name;
      _phoneController.text = widget.customer!.phone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Customer' : 'Add Customer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Customer Name ─────────────────────────────
              const Text(
                'Full Name *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Ali Raza',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter customer name';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Phone Number ──────────────────────────────
              const Text(
                'Phone Number *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  hintText: '03XX-XXXXXXX',
                  prefixIcon: Icon(Icons.phone_outlined),
                  helperText: 'Pakistani phone number format',
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  // Only allow digits, dashes, and spaces
                  FilteringTextInputFormatter.allow(RegExp(r'[\d\-\s\+]')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter a phone number';
                  // Basic length check — at least 10 digits
                  final digits = v.replaceAll(RegExp(r'\D'), '');
                  if (digits.length < 10) return 'Please enter a valid phone number';
                  return null;
                },
              ),

              const SizedBox(height: 40),

              // ── Save Button ───────────────────────────────
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveCustomer,
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
                label: Text(_isSaving
                    ? 'Saving...'
                    : (_isEditing ? 'Update Customer' : 'Add Customer')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<CustomerProvider>();
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();

    bool success;

    if (_isEditing) {
      success = await provider.updateCustomer(
        widget.customer!.copyWith(name: name, phone: phone),
      );
    } else {
      success = await provider.addCustomer(
        Customer(name: name, phone: phone),
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      showSuccessSnackBar(
        context,
        _isEditing ? '$name updated successfully' : '$name added successfully',
      );
      Navigator.pop(context);
    } else {
      showErrorSnackBar(
        context,
        provider.error ?? 'Something went wrong. Please try again.',
      );
    }
  }
}
