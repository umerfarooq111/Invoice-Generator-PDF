// ============================================================
// screens/products/products_screen.dart
// Lists all products with options to add, edit, and delete
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../widgets/common_widgets.dart';
import 'add_edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _currencyFmt = NumberFormat('#,##0.00', 'en_US');

  @override
  void initState() {
    super.initState();
    // Load products from DB on first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          // Product count badge
          Consumer<ProductProvider>(
            builder: (_, p, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${p.products.length} items',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),

      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          // Show loading spinner while fetching
          if (provider.isLoading) return const LoadingIndicator();

          // Show empty state if no products
          if (provider.products.isEmpty) {
            return const EmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products yet',
              subtitle: 'Tap the + button below to add your first product',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: provider.products.length,
            itemBuilder: (_, i) {
              final product = provider.products[i];
              return _ProductTile(
                product: product,
                currencyFmt: _currencyFmt,
                onEdit: () => _openAddEditSheet(context, product: product),
                onDelete: () => _confirmDelete(context, provider, product),
              );
            },
          );
        },
      ),

      // Floating button to add a new product
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  /// Open the Add/Edit bottom sheet
  void _openAddEditSheet(BuildContext context, {Product? product}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditProductScreen(product: product),
      ),
    );
  }

  /// Show delete confirmation and delete the product
  Future<void> _confirmDelete(
    BuildContext context,
    ProductProvider provider,
    Product product,
  ) async {
    final confirmed = await showDeleteConfirmDialog(context, itemName: product.name);
    if (confirmed == true && context.mounted) {
      final success = await provider.deleteProduct(product.id!);
      if (!success && context.mounted) {
        showErrorSnackBar(context, 'Failed to delete ${product.name}');
      } else if (context.mounted) {
        showSuccessSnackBar(context, '${product.name} deleted');
      }
    }
  }
}

// ─── Product List Tile ────────────────────────────────────

class _ProductTile extends StatelessWidget {
  final Product product;
  final NumberFormat currencyFmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductTile({
    required this.product,
    required this.currencyFmt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary,
          child: Text(
            // Show first letter of product name
            product.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          'Stock: ${product.stock} units',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'PKR ${currencyFmt.format(product.price)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                    fontSize: 14,
                  ),
                ),
                const Text(
                  'per unit',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Edit & delete icon buttons
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') onEdit();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: const Icon(Icons.edit_outlined),
                    title: const Text('Edit'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text('Delete', style: TextStyle(color: Colors.red)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

