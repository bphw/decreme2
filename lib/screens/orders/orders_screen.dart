import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/models.dart';
import '../../providers/order_provider.dart';
import 'order_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/supabase_config.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  OrderStatus? _selectedStatus;
  DateTimeRange? selectedRange;

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

  Future<List<Order>> _fetchOrdersForClientAndRange(String clientId, DateTimeRange range) async {
    final response = await SupabaseConfig.client
        .from('orders')
        .select()
        .eq('client_id', clientId)
        .gte('created_at', range.start.toIso8601String())
        .lte('created_at', range.end.toIso8601String());
    return (response as List).map((json) => Order.fromJson(json)).toList();
  }

  Future<void> _generateAndShareInvoice(Client client, DateTimeRange range) async {
    final orders = await _fetchOrdersForClientAndRange(client.id.toString(), range);
    if (orders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No orders found for this client and date range.')),
      );
      return;
    }

    Uint8List? logoBytes;
    if (client.logo != null && client.logo!.isNotEmpty) {
      logoBytes = await networkImageToBytes(client.logo!);
    }

    final pdf = pw.Document();
    final total = orders.fold<double>(0, (sum, o) => sum + o.totalAmount.toDouble());

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logoBytes != null)
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(logoBytes),
                  height: 60,
                ),
              ),
            pw.SizedBox(height: 8),
            pw.Text('Invoice for Client: ${client.name}', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            if (client.phone != null && client.phone.isNotEmpty)
              pw.Text('Phone: ${client.phone}'),
            pw.Text('Period: ${DateFormat('dd MMM yyyy').format(range.start)} - ${DateFormat('dd MMM yyyy').format(range.end)}'),
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['Order #', 'Date', 'Total'],
              data: orders.map((o) => [
                o.orderNumber.toString(),
                DateFormat('dd MMM yyyy').format(o.createdAt),
                'Rp ${formatPrice(o.totalAmount)}',
              ]).toList(),
            ),
            pw.SizedBox(height: 16),
            pw.Text('Total: Rp ${formatPrice(total)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );

    final pdfBytes = await pdf.save();
    await Printing.sharePdf(bytes: pdfBytes, filename: 'invoice.pdf');
  }

  Future<List<Client>> _fetchClients() async {
    final response = await SupabaseConfig.client
        .from('clients')
        .select('*');
    return (response as List).map((json) => Client.fromJson(json)).toList();
  }

  Future<void> _showInvoiceDialog(BuildContext context) async {
    // Fetch clients from your provider or Supabase
    final clients = await _fetchClients();
    Client? selectedClient;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Generate Invoice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Client>(
                decoration: const InputDecoration(labelText: 'Client'),
                items: clients.map((client) => DropdownMenuItem<Client>(
                  value: client,
                  child: Text(client.name),
                )).toList(),
                onChanged: (value) => selectedClient = value,
              ),
              ElevatedButton(
                onPressed: () async {
                  final now = DateTime.now();
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: now,
                    initialDateRange: selectedRange ??
                        DateTimeRange(
                          start: now.subtract(const Duration(days: 7)),
                          end: now,
                        ),
                  );
                  if (picked != null) {
                    selectedRange = picked;
                    // Optionally, call setState or use a StatefulBuilder to update the UI
                  }
                },
                child: Text(
                  selectedRange == null
                      ? 'Select Date Range'
                      : '${DateFormat('dd MMM yyyy').format(selectedRange!.start)} - ${DateFormat('dd MMM yyyy').format(selectedRange!.end)}',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (selectedClient != null && selectedRange != null) {
                  Navigator.pop(context);
                  await _generateAndShareInvoice(selectedClient!, selectedRange!);
                }
              },
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Generate Invoice',
            onPressed: () => _showInvoiceDialog(context),
          ),
        ],
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

Future<Uint8List> networkImageToBytes(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    return response.bodyBytes;
  }
  throw Exception('Failed to load image');
} 