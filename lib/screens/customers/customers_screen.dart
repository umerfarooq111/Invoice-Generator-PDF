// ============================================================
// screens/customers/customers_screen.dart
// Lists all customers with options to add, edit, and delete
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/customer_provider.dart';
import '../../models/customer.dart';
import '../../widgets/common_widgets.dart';
import 'add_edit_customer_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          Consumer<CustomerProvider>(
            builder: (_, p, __) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text('${p.customers.length} customers'),
              ),
            ),
          ),
        ],
      ),

      body: Consumer<CustomerProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const LoadingIndicator();

          if (provider.customers.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No customers yet',
              subtitle: 'Tap the + button to add your first customer',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 80),
            itemCount: provider.customers.length,
            itemBuilder: (_, i) {
              final customer = provider.customers[i];
              return _CustomerTile(
                customer: customer,
                onEdit: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddEditCustomerScreen(customer: customer),
                  ),
                ),
                onDelete: () => _confirmDelete(context, provider, customer),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditCustomerScreen()),
        ),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Customer'),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CustomerProvider provider,
    Customer customer,
  ) async {
    final confirmed = await showDeleteConfirmDialog(context, itemName: customer.name);
    if (confirmed == true && context.mounted) {
      final success = await provider.deleteCustomer(customer.id!);
      if (!success && context.mounted) {
        showErrorSnackBar(context, 'Failed to delete ${customer.name}');
      } else if (context.mounted) {
        showSuccessSnackBar(context, '${customer.name} deleted');
      }
    }
  }
}

// ─── Customer Tile ────────────────────────────────────────

class _CustomerTile extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerTile({
    required this.customer,
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
          backgroundColor: Colors.green.shade700,
          child: Text(
            customer.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Row(
          children: [
            const Icon(Icons.phone_outlined, size: 13, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              customer.phone,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'edit') onEdit();
            if (v == 'delete') onDelete();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: ListTile(
              leading: Icon(Icons.edit_outlined),
              title: Text('Edit'),
              contentPadding: EdgeInsets.zero,
            )),
            const PopupMenuItem(value: 'delete', child: ListTile(
              leading: Icon(Icons.delete_outline, color: Colors.red),
              title: Text('Delete', style: TextStyle(color: Colors.red)),
              contentPadding: EdgeInsets.zero,
            )),
          ],
        ),
      ),
    );
  }
}
