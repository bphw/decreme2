import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/order_provider.dart';
import 'order_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/supabase_config.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderStatus? _selectedStatus;

  String formatPrice(dynamic price) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(price.toDouble());
  }

  Future<String?> _getDeliveryFee() async {
    try {
      final response = await SupabaseConfig.client
          .from('settings')
          .select('setting_value')
          .eq('name', 'invoice_delivery_fee')
          .single();
      
      return response?['setting_value'];
    } catch (e) {
      print('Error fetching delivery fee: $e');
      return null;
    }
  }

  Future<void> _shareToWhatsApp(Order order) async {
    try {
      final message = '''
*Order #${order.orderNumber}*
Date: ${DateFormat('dd MMM yyyy').format(order.createdAt)}
Buyer: ${order.buyerName ?? "N/A"}
Phone: ${order.buyerPhone ?? "N/A"}
Total: Rp ${formatPrice(order.totalAmount)}
Status: ${order.status.name.toUpperCase()}
${order.notes != null ? 'Notes: ${order.notes}' : ''}
''';

      final whatsappUrl = Uri.parse(
        'whatsapp://send?text=${Uri.encodeComponent(message)}',
      );

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not launch WhatsApp'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing to WhatsApp: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: ${error.toString()}'),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          // Group orders by status
          final ordersByStatus = <OrderStatus, List<Order>>{};
          for (final status in OrderStatus.values) {
            ordersByStatus[status] = orders.where((o) => o.status == status).toList();
          }

          return Column(
            children: [
              // Status filter chips
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedStatus == null,
                      onSelected: (_) => setState(() => _selectedStatus = null),
                    ),
                    const SizedBox(width: 8),
                    ...OrderStatus.values.map((status) {
                      final count = ordersByStatus[status]?.length ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${status.name} ($count)'),
                          selected: _selectedStatus == status,
                          onSelected: (_) => setState(() => _selectedStatus = status),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              // Orders list
              Expanded(
                child: ListView.builder(
                  itemCount: (_selectedStatus == null 
                    ? orders 
                    : ordersByStatus[_selectedStatus] ?? []).length,
                  itemBuilder: (context, index) {
                    final filteredOrders = _selectedStatus == null 
                      ? orders 
                      : ordersByStatus[_selectedStatus] ?? [];
                    final order = filteredOrders[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(
                          'Order #${order.orderNumber}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd MMM yyyy').format(order.createdAt),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            FutureBuilder<String?>(
                              future: _getDeliveryFee(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Text(
                                    'Delivery Fee: Rp ${formatPrice(double.parse(snapshot.data ?? "0"))}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            Text(
                              'Total: Rp ${formatPrice(order.totalAmount)}',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Status: ${order.status.name.toUpperCase()}',
                              style: TextStyle(
                                color: _getStatusColor(order.status, colorScheme),
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'details',
                              child: Text('View Details'),
                            ),
                            const PopupMenuItem(
                              value: 'whatsapp',
                              child: Text('Share to WhatsApp'),
                            ),
                          ],
                          onSelected: (value) async {
                            switch (value) {
                              case 'details':
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailScreen(order: order),
                                  ),
                                );
                                break;
                              case 'whatsapp':
                                await _shareToWhatsApp(order);
                                break;
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _getStatusColor(OrderStatus status, ColorScheme colorScheme) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return colorScheme.primary;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.paid:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
} 