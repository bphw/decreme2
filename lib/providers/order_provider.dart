import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'cart_provider.dart';
import 'settings_provider.dart';

final orderProvider = StateNotifierProvider<OrderNotifier, AsyncValue<void>>((ref) {
  return OrderNotifier(ref);
});

class OrderNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;
  
  OrderNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> createOrder({
    required String buyerName,
    required String buyerPhone,
    String? notes,
    int? clientId,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      print('Creating order for user: ${user.email}');
      print('User ID: ${user.id}');
      
      // Get cart items to add to order
      final cartState = _ref.read(cartProvider);
      if (cartState.items.isEmpty) {
        throw Exception('Cart is empty');
      }

      // 1. First, create the order
      final orderResponse = await Supabase.instance.client
          .from('orders')
          .insert({
            'buyer_name': buyerName,
            'buyer_phone': buyerPhone,
            'notes': notes,
            'client_id': clientId,
            'created_by': user.email,
            'status': 'pending',
            'total_amount': cartState.total.toString(),
            'delivery_fee': cartState.deliveryFee.toString(),
            'ppn': cartState.tax.toString(),
            'order_number': 'ORD${DateTime.now().millisecondsSinceEpoch}',
          })
          .select()
          .single();

      print('Order created successfully: ${orderResponse['id']}');

      // 2. Then, add order items
      final orderItems = cartState.items.map((item) => {
        'order_id': orderResponse['id'],
        'cake_id': item.cake.id,
        'quantity': item.quantity,
        'price': item.cake.price.toString(),
      }).toList();

      await Supabase.instance.client
          .from('order_items')
          .insert(orderItems);

      print('Order items added successfully');

      // 3. Finally, clear the cart
      _ref.read(cartProvider.notifier).clear();
      print('Cart cleared successfully');

      // 4. Update state with the created order
      state = AsyncValue.data(orderResponse);
    } catch (e, st) {
      print('Error creating order: $e');
      print('Stack trace: $st');
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final ordersProvider = FutureProvider<List<Order>>((ref) async {
  try {
    final response = await Supabase.instance.client
        .from('orders')
        .select()
        .order('created_at', ascending: false);

    if (response == null) return [];

    final orders = (response as List)
        .map((json) => Order.fromJson(json))
        .toList();

    // Check if we're in demo mode
    final settings = ref.read(settingsProvider);
    final isDemoMode = settings.when(
      loading: () => false,
      error: (_, __) => false,
      data: (settings) => settings['is_demo_mode'] == 'true',
    );

    if (isDemoMode) {
      // In demo mode, limit pending orders to 5
      final pendingOrders = orders.where((o) => o.status == OrderStatus.pending).take(5).toList();
      final otherOrders = orders.where((o) => o.status != OrderStatus.pending).toList();
      return [...pendingOrders, ...otherOrders];
    }

    return orders;
  } catch (e) {
    print('Error fetching orders: $e');
    throw e;
  }
});

final orderItemsProvider = FutureProvider.family<List<OrderItem>, int>((ref, orderId) async {
  try {
    final response = await Supabase.instance.client
        .from('order_items')
        .select()
        .eq('order_id', orderId);

    if (response == null) return [];

    return (response as List)
        .map((json) => OrderItem.fromJson(json))
        .toList();
  } catch (e) {
    print('Error fetching order items: $e');
    throw e;
  }
}); 