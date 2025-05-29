import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/order_history_provider.dart';
import '../../models/models.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends ConsumerWidget {
  const OrderHistoryScreen({super.key});

  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(price.toDouble());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(orderHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order History'),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('No orders yet'))
            : ListView.builder(
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return OrderHistoryCard(order: order);
                },
              ),
      ),
    );
  }
}

class OrderHistoryCard extends ConsumerWidget {
  final Order order;

  const OrderHistoryCard({super.key, required this.order});

  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(price.toDouble());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.orderNumber}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                PopupMenuButton<OrderStatus>(
                  initialValue: order.status,
                  itemBuilder: (BuildContext context) => OrderStatus.values
                      .map((status) => PopupMenuItem<OrderStatus>(
                            value: status,
                            child: Text(status.name),
                          ))
                      .toList(),
                  onSelected: (OrderStatus newStatus) async {
                    // Show confirmation dialog
                    final shouldUpdate = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Update Status'),
                        content: Text(
                          'Change order status to ${newStatus.name}?'
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Update'),
                          ),
                        ],
                      ),
                    );

                    if (shouldUpdate == true) {
                      await ref.read(orderHistoryProvider.notifier).updateOrderStatus(
                        orderId: order.id.toString(),
                        newStatus: newStatus,
                      );
                    }
                  },
                  child: Chip(
                    label: Text(order.status.name),
                    backgroundColor: _getStatusColor(order.status),
                  ),
                ),
              ],
            ),
            const Divider(),
            Text(
              'Total: Rp ${formatPrice(order.totalAmount)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Date: ${DateFormat('dd MMM yyyy HH:mm').format(order.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (order.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${order.notes}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange.shade100;
      case OrderStatus.confirmed:
        return Colors.blue.shade100;
      case OrderStatus.preparing:
        return Colors.purple.shade100;
      case OrderStatus.ready:
        return Colors.green.shade100;
      case OrderStatus.completed:
        return Colors.grey.shade100;
      case OrderStatus.cancelled:
        return Colors.red.shade100;
      case OrderStatus.paid:
        return Colors.green.shade100;
    }
  }
} 