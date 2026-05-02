// ============================================================
// screens/products/add_edit_product_screen.dart
// Form screen for adding a new product or editing an existing one
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common_widgets.dart';

class AddEditProductScreen extends StatefulWidget {
  /// If [product] is provided, we are in "edit" mode; otherwise "add" mode
  final Product? product;

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  bool _isSaving = false;

  // Are we editing an existing product?
  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    // Pre-fill form if editing
    if (_isEditing) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toString();
      _stockController.text = widget.product!.stock.toString();
    }
  }

  @override
  void dispose() {
    // Always dispose controllers to avoid memory leaks
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Product' : 'Add Product'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Product Name ──────────────────────────────
              const Text(
                'Product Name *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Chai, Samosa, T-Shirt',
                  prefixIcon: Icon(Icons.inventory_2_outlined),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter a product name';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Unit Price ────────────────────────────────
              const Text(
                'Unit Price (PKR) *',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  hintText: 'e.g. 150.00',
                  prefixIcon: Icon(Icons.attach_money),
                  prefixText: 'PKR ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  // Only allow numbers and decimal point
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Please enter a price';
                  final price = double.tryParse(v);
                  if (price == null || price <= 0) return 'Please enter a valid price';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // ── Stock Quantity ────────────────────────────
              const Text(
                'Stock Quantity',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  hintText: '0',
                  prefixIcon: Icon(Icons.warehouse_outlined),
                  helperText: 'Optional — leave 0 if tracking not needed',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),

              const SizedBox(height: 40),

              // ── Save Button ───────────────────────────────
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveProduct,
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
                    : (_isEditing ? 'Update Product' : 'Add Product')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Validates the form and saves/updates the product
  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final provider = context.read<ProductProvider>();
    final name = _nameController.text.trim();
    final price = double.parse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim()) ?? 0;

    bool success;

    if (_isEditing) {
      // Update existing product
      final updated = widget.product!.copyWith(
        name: name,
        price: price,
        stock: stock,
      );
      success = await provider.updateProduct(updated);
    } else {
      // Add new product
      success = await provider.addProduct(
        Product(name: name, price: price, stock: stock),
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
