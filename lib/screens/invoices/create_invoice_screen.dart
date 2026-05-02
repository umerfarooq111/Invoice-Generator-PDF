// ============================================================
// screens/invoices/create_invoice_screen.dart
// Create a new invoice: select customer + add product items
// Includes custom title, notes, shop address, and T&C fields
// Auto-fills defaults from Settings
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/customer.dart';
import '../../models/invoice.dart';
import '../../models/invoice_item.dart';
import '../../models/product.dart';
import '../../providers/customer_provider.dart';
import '../../providers/invoice_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/common_widgets.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _currencyFmt = NumberFormat('#,##0.00', 'en_US');

  // Controllers for new fields
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _shopAddressController = TextEditingController();
  final _termsController = TextEditingController();

  // Currently selected customer
  Customer? _selectedCustomer;

  // Items added to this invoice
  final List<InvoiceItem> _items = [];

  bool _isSaving = false;

  // Toggle for showing the "Additional Info" section
  bool _showAdditionalInfo = false;

  // Grand total (recalculated whenever items change)
  double get _total => Invoice.calculateTotal(_items);

  @override
  void initState() {
    super.initState();

    // Auto-fill defaults from Settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoFillFromSettings();
    });
  }

  /// Pre-fill fields from saved shop settings
  void _autoFillFromSettings() {
    final settings = context.read<SettingsProvider>().settings;

    if (settings.shopAddress.isNotEmpty) {
      _shopAddressController.text = settings.shopAddress;
    }
    if (settings.defaultTerms.isNotEmpty) {
      _termsController.text = settings.defaultTerms;
    }
    if (settings.defaultNotes.isNotEmpty) {
      _notesController.text = settings.defaultNotes;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _shopAddressController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Invoice Title ───────────────────────────
                  _SectionCard(
                    title: 'Invoice Title',
                    icon: Icons.badge_outlined,
                    child: TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. "June Order - Ali Shop"',
                        prefixIcon: Icon(Icons.edit_outlined),
                        helperText:
                            'Optional — give a custom name for easy identification',
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Customer Selection ────────────────────
                  _SectionCard(
                    title: 'Select Customer',
                    icon: Icons.person_outline,
                    child: _buildCustomerSelector(),
                  ),

                  const SizedBox(height: 16),

                  // ── Products Section ──────────────────────
                  _SectionCard(
                    title: 'Add Products',
                    icon: Icons.inventory_2_outlined,
                    trailing: TextButton.icon(
                      onPressed: _showAddProductDialog,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Item'),
                    ),
                    child: _buildItemsList(),
                  ),

                  const SizedBox(height: 16),

                  // ── Additional Information Toggle ─────────
                  InkWell(
                    onTap: () =>
                        setState(() => _showAdditionalInfo = !_showAdditionalInfo),
                    borderRadius: BorderRadius.circular(12),
                    child: Card(
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.note_add_outlined,
                                size: 18, color: primary),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Additional Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            Text(
                              _showAdditionalInfo ? 'Hide' : 'Show',
                              style: TextStyle(
                                color: primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(
                              _showAdditionalInfo
                                  ? Icons.keyboard_arrow_up
                                  : Icons.keyboard_arrow_down,
                              color: primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Additional Info Fields (Collapsible) ──
                  if (_showAdditionalInfo) ...[
                    const SizedBox(height: 16),
                    _SectionCard(
                      title: 'Shop Address',
                      icon: Icons.store_outlined,
                      child: TextFormField(
                        controller: _shopAddressController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. "Shop #5, Main Bazar, Lahore"',
                          prefixIcon: Icon(Icons.location_on_outlined),
                          helperText: 'Printed on the invoice (auto-filled from Settings)',
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.words,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'Notes / Messages',
                      icon: Icons.sticky_note_2_outlined,
                      child: TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. "Payment due within 7 days. Thank you!"',
                          prefixIcon: Icon(Icons.message_outlined),
                          helperText: 'Auto-filled from Settings defaults',
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _SectionCard(
                      title: 'Terms & Conditions',
                      icon: Icons.gavel_outlined,
                      child: TextFormField(
                        controller: _termsController,
                        decoration: const InputDecoration(
                          hintText:
                              'e.g. "No returns after 3 days."',
                          prefixIcon: Icon(Icons.description_outlined),
                          helperText: 'Auto-filled from Settings defaults',
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ── Bottom Total & Save Bar ───────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Total row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Grand Total',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'PKR ${_currencyFmt.format(_total)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Save invoice button
                ElevatedButton.icon(
                  onPressed:
                      (_isSaving || _selectedCustomer == null || _items.isEmpty)
                          ? null
                          : _saveInvoice,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_alt_outlined),
                  label: Text(
                    _isSaving ? 'Saving Invoice...' : 'Save Invoice',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Customer Selector ────────────────────────────────────

  Widget _buildCustomerSelector() {
    final customers = context.watch<CustomerProvider>().customers;

    if (customers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No customers found. Add a customer first.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return DropdownButtonFormField<Customer>(
      value: _selectedCustomer,
      decoration: const InputDecoration(
        hintText: 'Choose a customer',
        prefixIcon: Icon(Icons.person_pin_outlined),
      ),
      items: customers.map((c) {
        return DropdownMenuItem<Customer>(
          value: c,
          child: Text('${c.name} – ${c.phone}'),
        );
      }).toList(),
      onChanged: (c) => setState(() => _selectedCustomer = c),
    );
  }

  // ─── Items List ───────────────────────────────────────────

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.add_shopping_cart_outlined,
                  size: 40, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                'No items added yet',
                style: TextStyle(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap "Add Item" to add products',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _InvoiceItemRow(
          item: item,
          currencyFmt: _currencyFmt,
          onRemove: () => setState(() => _items.removeAt(index)),
          onQtyChange: (newQty) {
            setState(() {
              _items[index] = item.copyWith(quantity: newQty);
            });
          },
        );
      }).toList(),
    );
  }

  // ─── Add Product Dialog ───────────────────────────────────

  void _showAddProductDialog() {
    final products = context.read<ProductProvider>().products;

    if (products.isEmpty) {
      showErrorSnackBar(context, 'No products available. Add products first.');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _ProductPickerSheet(
        products: products,
        onProductSelected: (product, qty) {
          setState(() {
            // If product already in list, increase quantity
            final existingIndex = _items.indexWhere(
              (item) => item.productId == product.id,
            );
            if (existingIndex != -1) {
              final existing = _items[existingIndex];
              _items[existingIndex] =
                  existing.copyWith(quantity: existing.quantity + qty);
            } else {
              _items.add(InvoiceItem(
                productId: product.id!,
                productName: product.name,
                unitPrice: product.price,
                quantity: qty,
              ));
            }
          });
        },
      ),
    );
  }

  // ─── Save Invoice ─────────────────────────────────────────

  Future<void> _saveInvoice() async {
    if (_selectedCustomer == null || _items.isEmpty) return;

    setState(() => _isSaving = true);

    final invoiceProvider = context.read<InvoiceProvider>();
    final productProvider = context.read<ProductProvider>();

    // Get optional field values
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : null;
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;
    final shopAddress = _shopAddressController.text.trim().isNotEmpty
        ? _shopAddressController.text.trim()
        : null;
    final terms = _termsController.text.trim().isNotEmpty
        ? _termsController.text.trim()
        : null;

    final success = await invoiceProvider.createInvoice(
      customer: _selectedCustomer!,
      items: _items,
      title: title,
      notes: notes,
      shopAddress: shopAddress,
      termsConditions: terms,
    );

    if (!mounted) return;

    if (success) {
      // Deduct stock for all items in the invoice
      final productQtyMap = <int, int>{};
      for (final item in _items) {
        productQtyMap[item.productId] =
            (productQtyMap[item.productId] ?? 0) + item.quantity;
      }
      final outOfStockProducts =
          await productProvider.deductStockForInvoice(productQtyMap);

      if (!mounted) return;

      showSuccessSnackBar(context, 'Invoice saved successfully!');

      // Show out-of-stock alert if any products ran out
      if (outOfStockProducts.isNotEmpty) {
        _showOutOfStockAlert(outOfStockProducts);
      }

      Navigator.pop(context);
    } else {
      showErrorSnackBar(
        context,
        invoiceProvider.error ?? 'Failed to save invoice. Please try again.',
      );
    }

    setState(() => _isSaving = false);
  }

  /// Show a dialog alerting the user about products that went out of stock
  void _showOutOfStockAlert(List<Product> products) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: Colors.orange, size: 48),
        title: const Text('Restock Needed!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following products are now out of stock:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            ...products.map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 12),
            const Text(
              'Please restock these items to continue selling.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

// ─── Section Card Widget ──────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(icon, size: 18,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

// ─── Invoice Item Row ─────────────────────────────────────

class _InvoiceItemRow extends StatelessWidget {
  final InvoiceItem item;
  final NumberFormat currencyFmt;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChange;

  const _InvoiceItemRow({
    required this.item,
    required this.currencyFmt,
    required this.onRemove,
    required this.onQtyChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Product name & price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  'PKR ${currencyFmt.format(item.unitPrice)} each',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),

          // Quantity stepper
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  if (item.quantity > 1) onQtyChange(item.quantity - 1);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: const Icon(Icons.remove, size: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  '${item.quantity}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              InkWell(
                onTap: () => onQtyChange(item.quantity + 1),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(width: 12),

          // Subtotal + remove
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PKR ${currencyFmt.format(item.subtotal)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 13),
              ),
              InkWell(
                onTap: onRemove,
                child: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(Icons.close, size: 16, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Product Picker Bottom Sheet ──────────────────────────

class _ProductPickerSheet extends StatefulWidget {
  final List<Product> products;
  final Function(Product, int) onProductSelected;

  const _ProductPickerSheet({
    required this.products,
    required this.onProductSelected,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  Product? _selected;
  late TextEditingController _qtyController;
  final _currencyFmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  int get _qty => int.tryParse(_qtyController.text) ?? 1;

  void _updateQty(int newQty) {
    if (newQty < 1) return;
    setState(() {
      _qtyController.text = newQty.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Product to Invoice',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Product dropdown
          DropdownButtonFormField<Product>(
            value: _selected,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Select Product',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
            items: widget.products.map((p) {
              final isOut = p.isOutOfStock;
              return DropdownMenuItem<Product>(
                value: p,
                enabled: !isOut,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${p.name} – PKR ${_currencyFmt.format(p.price)}',
                        style: TextStyle(
                          color: isOut ? Colors.grey : null,
                          decoration: isOut ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    if (isOut)
                      _buildBadge('OUT', Colors.red)
                    else if (p.isLowStock)
                      _buildBadge('${p.stock} left', Colors.orange),
                  ],
                ),
              );
            }).toList(),
            onChanged: (p) => setState(() => _selected = p),
          ),

          if (_selected != null && _selected!.isLowStock)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.orange.shade700),
                  const SizedBox(width: 6),
                  Text(
                    'Only ${_selected!.stock} units left in stock!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Quantity selector
          Row(
            children: [
              const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                onPressed: _qty > 1 ? () => _updateQty(_qty - 1) : null,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              SizedBox(
                width: 60,
                child: TextFormField(
                  controller: _qtyController,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _updateQty(_qty + 1),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),

          if (_selected != null && _qty > _selected!.stock && _selected!.stock > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Warning: Quantity exceeds available stock (${_selected!.stock})',
                style: TextStyle(fontSize: 12, color: Colors.red.shade700),
              ),
            ),

          const SizedBox(height: 32),

          // Confirm button
          ElevatedButton.icon(
            onPressed: _selected == null
                ? null
                : () {
                    widget.onProductSelected(_selected!, _qty);
                    Navigator.pop(context);
                  },
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to Invoice'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color.withOpacity(0.8),
        ),
      ),
    );
  }
}

